atom_feed :language => 'en-US', 'xmlns:g'=> "http://base.google.com/ns/1.0" do |feed|
  feed.title title
  feed.updated updated
  feed.icon "https://s3.amazonaws.com/sharetribe/assets/sharetribe_icon.png"
  feed.logo "https://s3.amazonaws.com/sharetribe/assets/dashboard/sharetribe_logo.png"

  google_product_category = Hash.new
  google_product_category[3] = "182"
  google_product_category[4] = "187"
  google_product_category[11] = "5422"
  google_product_category[12] = "568"
  google_product_category[13] = "1241"
  google_product_category[14] = "538"
  google_product_category[15] = "547"
  google_product_category[16] = "2847"
  google_product_category[17] = "3661"
  google_product_category[18] = "1243"
  google_product_category[19] = "6394"
  google_product_category[20] = "559"
  google_product_category[21] = "554"
  google_product_category[22] = "5296"
  google_product_category[23] = "565"
  google_product_category[24] = "548"
  google_product_category[25] = "96"
  google_product_category[30] = "522987"
  google_product_category[32] = "561"
  google_product_category[33] = "555"
  google_product_category[34] = "4679"

  listings.each do |listing|
    if listing[:price].to_i != 0 && listing[:listing_shape_id] == 1 && !listing[:listing_images].blank? && listing[:category_id] != 10 && !listing[:description].blank?
      feed.entry(nil, id: "#{request.protocol}#{request.host_with_port}/listings/#{listing[:id]}", published: listing[:created_at], updated_at: listing[:updated_at], url: listing_url(listing[:url], host: @current_community.full_domain(port: ''))) do |entry|
        entry.title listing[:title]
        entry_content = add_links_and_br_tags(html_escape(listing[:description]))
        unless listing[:listing_images].empty?

          img_url = ensure_full_image_url(listing[:listing_images].first[:medium])

          entry_content +=  "<br />\n" + link_to(image_tag(img_url), listing_url(listing[:url], host: @current_community.full_domain(port: '')))
        end

        entry.content :type => 'html' do |content|
          entry.cdata!( entry_content )
        end

        entry.st :listing_type, :term => direction_map[listing[:listing_shape_id]], :label => localized_listing_type_label(direction_map[listing[:listing_shape_id]])

        # TODO: add scheme link to point to url where that category of that community is shown
        entry.category :term => listing[:category_id], :label => localized_category_from_id(listing[:category_id])


        entry.st :share_type, :term => listing[:listing_shape_id], :label => t(listing[:shape_name_tr_key]).capitalize if listing[:shape_name_tr_key]

        entry.author do |author|
          author.name PersonViewUtils.person_entity_display_name(listing[:author], @current_community.name_display_type)
        end

        if listing[:latitude] || listing[:longitude] || listing[:address]
          entry.georss :point, "#{listing[:latitude]} #{listing[:longitude]}"
          entry.st :address, listing[:address]
        end

        entry.st :comment_count, listing[:comment_count]

        category_id = listing[:category_id]
        if google_product_category[category_id].blank?
          google_category_id = 537
        else
          google_category_id = google_product_category[category_id]
        end
        
        if !brand_hash.blank?
          listing_id = listing[:id]
          brand = brand_hash["#{listing_id}"]
          if brand.blank?
            brand = "secondcry"
          end
        end

        entry.summary listing[:description]

        entry.g :image_link, "#{request.protocol}#{request.host_with_port}#{img_url}"
        entry.g :price, listing[:price].to_i
        entry.g :condition, "used"
      end
    end
  end
end
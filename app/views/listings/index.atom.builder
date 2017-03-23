atom_feed :language => 'en-US', 'xmlns:g'=> "http://base.google.com/ns/1.0" do |feed|
  feed.title title
  feed.updated updated
  feed.icon "https://s3.amazonaws.com/sharetribe/assets/sharetribe_icon.png"
  feed.logo "https://s3.amazonaws.com/sharetribe/assets/dashboard/sharetribe_logo.png"

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

        # TODO: add scheme link to point to url where that category of that community is shown
        entry.category :term => listing[:category_id], :label => localized_category_from_id(listing[:category_id])

        entry.author do |author|
          author.name PersonViewUtils.person_entity_display_name(listing[:author], @current_community.name_display_type)
        end

        if listing[:latitude] || listing[:longitude] || listing[:address]
          entry.georss :point, "#{listing[:latitude]} #{listing[:longitude]}"
        end

        entry.summary listing[:description]

        entry.updated listing[:updated_at]

        entry.g :id, listing[:id]
        entry.g :title, listing[:title]
        entry.g :link, listing_url(listing[:url])
        entry.g :availability, "in stock"
        entry.g :identifier_exists, "no"
        entry.g :availability, "in stock"
        entry.g :description, listing[:description]
        entry.g :image_link, "#{request.protocol}#{request.host_with_port}#{img_url}"
        entry.g :price, "#{listing[:price]}" " " "INR"
        entry.g :condition, "used"
      end
    end
  end
end
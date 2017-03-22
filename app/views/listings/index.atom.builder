atom_feed :language => 'en-US', 'xmlns:georss' => 'http://www.georss.org/georss', 'xmlns:st'  => 'http://www.sharetribe.com/SharetribeFeed' do |feed|
  feed.title title
  feed.updated updated
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
      feed.entry(nil, id: listing[:id], url: listing_url(listing[:url], host: @current_community.full_domain(port: ''))) do |entry|
        entry.title listing[:title]
        unless listing[:listing_images].empty?

          img_url = ensure_full_image_url(listing[:listing_images].first[:medium])
        end
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
        entry.availability "In Stock"
        entry.identifier_exists "false"
        entry.google_product_category google_category_id
        entry.brand brand

        # TODO: add scheme link to point to url where that category of that community is shown
      end
    end
  end
end

class GoogleAnalyticsApiJob < Struct.new(:access_token)
   include DelayedAirbrakeNotification

  def perform
    api_url =  URI("https://www.googleapis.com/analytics/v3/data/ga?ids=ga%3A99461292&start-date=90daysAgo&end-date=yesterday&metrics=ga%3Apageviews&dimensions=ga%3ApagePath&sort=-ga%3ApagePath&filters=ga%3ApagePath%3D~%5C%2Flistings%5C%2F%5B0-9%5D%2B%24%2Cga%3ApagePath%3D~%5C%2Flistings%5C%2F%5B0-9%5D%2B-%5B%5E%5C%2F%5D*%24&max-results=10000&access_token=#{access_token}")

    begin      
      response = Net::HTTP.get(api_url)
      api_response = JSON.parse(response)

      if !api_response.blank? && !api_response["error"].blank? && !api_response["error"]["message"].blank?
        MailCarrier.deliver_now(CommunityMailer.google_analytics_api_update(api_url, "failure", api_response["error"]["code"], api_response["error"]["message"]))
      else
        listings = api_response["rows"]
        listing_views_hash = Hash.new
        listings.each{|l|
          listing_id = l[0].split('/listings/')[1].split('-')
          id = listing_id[0].to_i
          if listing_views_hash["#{id}"].blank?
            listing_views_hash["#{id}"] = l[1].to_i
          else
            listing_views_hash["#{id}"] = listing_views_hash["#{id}"] + l[1].to_i
          end
        }

        count = 0
        listing_views_hash.each{|k,v|
          listing = Listing.where("id = #{k.to_i}").first
          if !listing.blank?
            listing.times_viewed = v.to_i
            listing.save
            count = count + 1
          end
        }
        MailCarrier.deliver_now(CommunityMailer.google_analytics_api_update(api_url, "success", api_response["totalResults"], count))
      end
    rescue Exception => e
      MailCarrier.deliver_now(CommunityMailer.google_analytics_api_update(api_url, "failure", "510", "#{e.to_s}"))
    end
  end
end
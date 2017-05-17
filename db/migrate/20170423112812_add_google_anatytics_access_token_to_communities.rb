class AddGoogleAnatyticsAccessTokenToCommunities < ActiveRecord::Migration
  def change
  	add_column :communities, :google_analytics_access_token, :string
  end
end

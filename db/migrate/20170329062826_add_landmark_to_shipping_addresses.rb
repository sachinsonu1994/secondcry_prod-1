class AddLandmarkToShippingAddresses < ActiveRecord::Migration
  def change
    add_column :shipping_addresses, :landmark, :string
  end
end

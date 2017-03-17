class AddSellerIdToShippingAddresses < ActiveRecord::Migration
  def change
    add_column :shipping_addresses, :seller_id, :string
  end
end

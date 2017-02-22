class AddBuyerIdToShippingAddresses < ActiveRecord::Migration
  def change
    add_column :shipping_addresses, :buyer_id, :string
  end
end

class ChangeColumnToShippingAddresses < ActiveRecord::Migration
  def change
    rename_column :shipping_addresses, :seller_id, :address_type
    rename_column :shipping_addresses, :buyer_id, :person_id
  end
end

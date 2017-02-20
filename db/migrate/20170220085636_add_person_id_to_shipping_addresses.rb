class AddPersonIdToShippingAddresses < ActiveRecord::Migration
  def change
    add_column :shipping_addresses, :person_id, :string
  end
end

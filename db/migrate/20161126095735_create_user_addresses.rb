class CreateUserAddresses < ActiveRecord::Migration
  def change
    create_table :user_addresses do |t|
      t.belongs_to :person, index: true
      t.string :name
      t.string :address1
      t.string :address2
      t.string :landmark
      t.string :city
      t.string :pincode
      t.string :state
      t.string :country
      t.string :phone
      t.timestamps null: false
    end
  end
end

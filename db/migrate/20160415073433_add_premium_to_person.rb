class AddPremiumToPerson < ActiveRecord::Migration
  def change
    add_column :people, :is_premium, :boolean, :default => false
  end
end

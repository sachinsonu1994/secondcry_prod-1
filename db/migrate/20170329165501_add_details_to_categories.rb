class AddDetailsToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :shipping_charge, :string
    add_column :categories, :weight, :string
    add_column :categories, :height, :string
    add_column :categories, :width, :string
    add_column :categories, :length, :string
  end
end

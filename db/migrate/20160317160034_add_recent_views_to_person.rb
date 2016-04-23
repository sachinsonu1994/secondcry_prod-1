class AddRecentViewsToPerson < ActiveRecord::Migration
  def change
    add_column :people, :recent_views, :string
  end
end

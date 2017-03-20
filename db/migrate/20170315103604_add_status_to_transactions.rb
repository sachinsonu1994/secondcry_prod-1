class AddStatusToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :order_status, :string
  end
end

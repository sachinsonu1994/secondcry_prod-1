class AddLabelUrlToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :shipment_label_url, :string
  end
end

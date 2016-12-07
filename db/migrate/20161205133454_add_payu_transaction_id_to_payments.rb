class AddPayuTransactionIdToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payu_transaction_id, :integer
  end
end

class AddDetailsToBraintreeAccount < ActiveRecord::Migration
  def change
    add_column :braintree_accounts, :account_number, :string
    add_column :braintree_accounts, :bank_name_and_branch, :string
    add_column :braintree_accounts, :ifsc_number, :string
  end
end

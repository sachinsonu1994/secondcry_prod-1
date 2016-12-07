class AddPayuDetailsToPaymentGateways < ActiveRecord::Migration
  def change
    add_column :payment_gateways, :payu_merchant_id, :string
    add_column :payment_gateways, :payu_salt, :string
  end
end

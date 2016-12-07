# == Schema Information
#
# Table name: payment_gateways
#
#  id                                   :integer          not null, primary key
#  community_id                         :integer
#  type                                 :string(255)
#  braintree_environment                :string(255)
#  braintree_merchant_id                :string(255)
#  braintree_master_merchant_id         :string(255)
#  braintree_public_key                 :string(255)
#  braintree_private_key                :string(255)
#  braintree_client_side_encryption_key :text(65535)
#  checkout_environment                 :string(255)
#  checkout_user_id                     :string(255)
#  checkout_password                    :string(255)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  payu_merchant_id                     :string(255)
#  payu_salt                            :string(255)
#

class PayuPaymentGateway < PaymentGateway

  def can_receive_payments?(person)
    payu_account = person.payu_account
    payu_account.present? && payu_account.status == "active"
  end


  def new_payment_path(person, message, locale)
    edit_person_message_braintree_payment_path(:id => message.payment.id, :person_id => person.id.to_s, :message_id => message.id.to_s, :locale => locale)
  end

end

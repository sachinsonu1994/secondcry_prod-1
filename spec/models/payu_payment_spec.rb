# == Schema Information
#
# Table name: payments
#
#  id                       :integer          not null, primary key
#  payer_id                 :string(255)
#  recipient_id             :string(255)
#  organization_id          :string(255)
#  transaction_id           :integer
#  status                   :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  community_id             :integer
#  payment_gateway_id       :integer
#  sum_cents                :integer
#  currency                 :string(255)
#  type                     :string(255)      default("CheckoutPayment")
#  braintree_transaction_id :string(255)
#  payu_transaction_id      :integer
#
# Indexes
#
#  index_payments_on_conversation_id  (transaction_id)
#  index_payments_on_payer_id         (payer_id)
#

require 'rails_helper'

RSpec.describe PayuPayment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

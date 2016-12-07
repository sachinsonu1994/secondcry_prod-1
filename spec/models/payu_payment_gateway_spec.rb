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

require 'rails_helper'

RSpec.describe PayuPaymentGateway, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

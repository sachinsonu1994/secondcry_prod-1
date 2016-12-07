# == Schema Information
#
# Table name: user_addresses
#
#  id         :integer          not null, primary key
#  person_id  :integer
#  name       :string(255)
#  address1   :string(255)
#  address2   :string(255)
#  landmark   :string(255)
#  city       :string(255)
#  pincode    :string(255)
#  state      :string(255)
#  country    :string(255)
#  phone      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_addresses_on_person_id  (person_id)
#

require 'rails_helper'

RSpec.describe UserAddress, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

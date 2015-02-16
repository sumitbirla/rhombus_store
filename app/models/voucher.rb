# == Schema Information
#
# Table name: vouchers
#
#  id               :integer          not null, primary key
#  voucher_group_id :integer          not null
#  code             :string(255)      not null
#  claim_time       :datetime
#  claimed_by       :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class Voucher < ActiveRecord::Base
  self.table_name = "store_vouchers"
  belongs_to :voucher_group
  validates_presence_of :code, :voucher_group_id
end

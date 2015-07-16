# == Schema Information
#
# Table name: store_vouchers
#
#  id               :integer          not null, primary key
#  voucher_group_id :integer          not null
#  code             :string(255)      not null
#  issued           :boolean
#  amount_used      :decimal(10, 2)   default(0.0), not null
#  created_at       :datetime
#  updated_at       :datetime
#

class Voucher < ActiveRecord::Base
  self.table_name = "store_vouchers"
  belongs_to :voucher_group
  validates_presence_of :code, :voucher_group_id
end

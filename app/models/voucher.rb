# == Schema Information
#
# Table name: store_vouchers
#
#  id               :integer          not null, primary key
#  amount_used      :decimal(10, 2)   default(0.0), not null
#  code             :string(255)      not null
#  issued           :boolean
#  created_at       :datetime
#  updated_at       :datetime
#  voucher_group_id :integer          not null
#
# Indexes
#
#  index_vouchers_on_voucher_group_id  (voucher_group_id)
#

class Voucher < ActiveRecord::Base
  include Exportable
  self.table_name = "store_vouchers"
  belongs_to :voucher_group
  validates_presence_of :code, :voucher_group_id

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

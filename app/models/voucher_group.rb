# == Schema Information
#
# Table name: store_voucher_groups
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  value      :decimal(10, 2)   not null
#  expires    :datetime         not null
#  created_at :datetime
#  updated_at :datetime
#

class VoucherGroup < ActiveRecord::Base
  include Exportable
  self.table_name = "store_voucher_groups"
  has_many :vouchers
end

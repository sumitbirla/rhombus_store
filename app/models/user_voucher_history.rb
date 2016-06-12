# == Schema Information
#
# Table name: user_voucher_histories
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  voucher_id :integer
#  amount     :decimal(10, 2)   not null
#  order_id   :integer
#  notes      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class UserVoucherHistory < ActiveRecord::Base
  include Exportable
  self.table_name = "store_user_voucher_history"
  belongs_to :user
  belongs_to :voucher
  belongs_to :order
end

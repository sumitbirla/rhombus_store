# == Schema Information
#
# Table name: store_order_history
#
#  id          :integer          not null, primary key
#  amount      :decimal(10, 2)
#  comment     :string(255)
#  data1       :binary(65535)
#  data2       :binary(65535)
#  event_type  :string(255)      default(""), not null
#  identifier  :string(255)
#  system_name :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#  order_id    :integer          not null
#  user_id     :integer
#
# Indexes
#
#  index_order_histories_on_order_id  (order_id)
#

class OrderHistory < ActiveRecord::Base
  self.table_name = "store_order_history"
  belongs_to :order
  belongs_to :user
  default_scope { order('created_at DESC') }

  validates_presence_of :order_id, :event_type
end

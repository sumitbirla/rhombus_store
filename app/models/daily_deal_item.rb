# == Schema Information
#
# Table name: daily_deal_items
#
#  id            :integer          not null, primary key
#  daily_deal_id :integer          not null
#  product_id    :integer          not null
#  unit_cost     :decimal(8, 2)    not null
#  quantity      :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class DailyDealItem < ActiveRecord::Base
  self.table_name = "store_daily_deal_items"
  belongs_to :daily_deal
  belongs_to :product
end

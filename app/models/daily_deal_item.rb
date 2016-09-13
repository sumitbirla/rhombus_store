# == Schema Information
#
# Table name: store_daily_deal_items
#
#  id            :integer          not null, primary key
#  daily_deal_id :integer          not null
#  product_id    :integer          not null
#  affiliate_id  :integer
#  variation     :string(255)
#  unit_cost     :decimal(8, 2)    not null
#  quantity      :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class DailyDealItem < ActiveRecord::Base
  self.table_name = "store_daily_deal_items"
  belongs_to :daily_deal
  belongs_to :product
  belongs_to :affiliate
  
  def item_number
    str = ""
    str += product.item_number unless product_id.nil?
    str += "-" + affiliate.code unless affiliate_id.nil?
    str += "-" + variation unless variation.blank?
    str
  end
end

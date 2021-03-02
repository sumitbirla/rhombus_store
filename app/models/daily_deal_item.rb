# == Schema Information
#
# Table name: store_daily_deal_items
#
#  id            :integer          not null, primary key
#  quantity      :integer          not null
#  unit_cost     :decimal(8, 2)    not null
#  variation     :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  affiliate_id  :integer
#  daily_deal_id :integer          not null
#  product_id    :integer          not null
#
# Indexes
#
#  index_daily_deal_items_on_daily_deal_id       (daily_deal_id)
#  index_daily_deal_items_on_product_id          (product_id)
#  index_store_daily_deal_items_on_affiliate_id  (affiliate_id)
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

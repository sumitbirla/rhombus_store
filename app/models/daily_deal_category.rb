# == Schema Information
#
# Table name: store_daily_deal_categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  category_id   :integer
#  daily_deal_id :integer
#
# Indexes
#
#  index_daily_deal_categories_on_category_id    (category_id)
#  index_daily_deal_categories_on_daily_deal_id  (daily_deal_id)
#

class DailyDealCategory < ActiveRecord::Base
  self.table_name = "store_daily_deal_categories"

  belongs_to :daily_deal
  belongs_to :category
end

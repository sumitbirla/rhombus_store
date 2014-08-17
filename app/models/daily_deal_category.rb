# == Schema Information
#
# Table name: daily_deal_categories
#
#  id            :integer          not null, primary key
#  daily_deal_id :integer
#  category_id   :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class DailyDealCategory < ActiveRecord::Base
  self.table_name = "store_daily_deal_categories"
  
  belongs_to :daily_deal
  belongs_to :category
end

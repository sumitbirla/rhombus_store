# == Schema Information
#
# Table name: store_daily_deal_locations
#
#  id            :integer          not null, primary key
#  daily_deal_id :integer          not null
#  location_id   :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class DailyDealLocation < ActiveRecord::Base
  self.table_name = "store_daily_deal_locations"
  belongs_to :daily_deal
  belongs_to :location
end

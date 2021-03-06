# == Schema Information
#
# Table name: store_daily_deal_locations
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  daily_deal_id :integer          not null
#  location_id   :integer          not null
#
# Indexes
#
#  index_daily_deal_locations_on_daily_deal_id  (daily_deal_id)
#  index_daily_deal_locations_on_location_id    (location_id)
#

class DailyDealLocation < ActiveRecord::Base
  self.table_name = "store_daily_deal_locations"
  belongs_to :daily_deal
  belongs_to :location
end

class RemoveRegionIdFromStoreDailyDeals < ActiveRecord::Migration
  def change
	remove_column :store_daily_deals, :region_id, :integer
  end
end

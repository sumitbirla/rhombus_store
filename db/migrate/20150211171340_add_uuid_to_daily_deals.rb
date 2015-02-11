class AddUuidToDailyDeals < ActiveRecord::Migration
  def change
    add_column :store_daily_deals, :uuid, :string, null: false
  end
end

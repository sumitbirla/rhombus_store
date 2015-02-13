class AddFieldsToDailyDealItems < ActiveRecord::Migration
  def change
    add_reference :store_daily_deal_items, :affiliate, index: true, after: :product_id
    add_column :store_daily_deal_items, :variation, :string, after: :affiliate_id
  end
end

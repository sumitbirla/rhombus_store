class AddDailyDealIdToStoreOrderItems < ActiveRecord::Migration
  def change
    add_reference :store_order_items, :daily_deal, index: true, after: :product_id
  end
end

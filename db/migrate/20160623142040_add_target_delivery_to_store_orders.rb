class AddTargetDeliveryToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :expected_delivery_date, :date
    add_column :store_order_items, :quantity_accepted, :integer, null: false, default: 0
    add_column :store_order_items, :quantity_received, :integer, null: false, default: 0
    add_column :store_affiliate_products, :ship_lead_time, :integer, null: false, default: 14
  end
end

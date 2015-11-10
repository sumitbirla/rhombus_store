class AddFbDiscountToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :fb_discount, :decimal, precision: 5, scale: 2, null: false, default: 0.0
  end
end

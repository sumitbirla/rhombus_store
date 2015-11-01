class AddAutoshipToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :auto_ship, :boolean, null: false, default: false
  end
end

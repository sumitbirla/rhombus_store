class AddEdiFieldsToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :allow_backorder, :boolean, null: false, default: false
    add_column :store_orders, :ship_earliest, :date
    add_column :store_orders, :ship_latest, :date
  end
end

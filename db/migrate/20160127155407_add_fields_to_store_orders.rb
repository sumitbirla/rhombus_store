class AddFieldsToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :po, :boolean, null: false, default: false
    add_column :store_orders, :payment_due, :date
  end
end

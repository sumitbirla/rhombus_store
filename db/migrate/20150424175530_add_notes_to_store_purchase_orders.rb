class AddNotesToStorePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :store_purchase_orders, :notes, :string
  end
end

class AddNotesToStorePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :store_purchase_orders, :notes, :string
    add_reference :store_purchase_orders, :affiliate, index: true, foreign_key: true
  end
end

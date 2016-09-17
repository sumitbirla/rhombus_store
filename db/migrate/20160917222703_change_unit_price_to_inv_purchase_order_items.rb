class ChangeUnitPriceToInvPurchaseOrderItems < ActiveRecord::Migration
  def change
	change_column :inv_purchase_order_items, :unit_price, :decimal, null: false, default: 0.0, precision: 12, scale: 4
  end
end

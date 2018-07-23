class DropColumnsFromInvTransactions < ActiveRecord::Migration
  def change
	remove_column :inv_transactions, :user_id
	remove_column :inv_transactions, :shipment_id
	remove_column :inv_transactions, :purchase_order_id
  end
end

class AddExternalIdToInvTransactions < ActiveRecord::Migration
  def change
    add_column :inv_transactions, :external_id, :string, after: :id
	add_column :store_shipments, :uuid, :string, after: :id
	add_column :inv_purchase_orders, :uuid, :string, after: :id
  end
end

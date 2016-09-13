class AddSkuToInvItems < ActiveRecord::Migration
  def change
    add_column :inv_items, :sku, :string, null: false
    add_column :inv_transactions, :shipment_id, :integer
    add_column :inv_transactions, :purchase_order_id, :integer
    remove_column :inv_transactions, :entity_type
    remove_column :inv_transactions, :entity_id
  end
end

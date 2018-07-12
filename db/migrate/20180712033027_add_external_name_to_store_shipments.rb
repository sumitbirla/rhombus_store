class AddExternalNameToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :external_name, :string, after: :external_id
	add_column :store_orders, :external_order_name, :string, after: :external_order_id
  end
end

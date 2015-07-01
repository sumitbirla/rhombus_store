class AddFlagsToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :fulfiller_notified, :boolean, null: false, default: false
    add_column :store_shipments, :inventory_updated, :boolean, null: false, default: false
  end
end

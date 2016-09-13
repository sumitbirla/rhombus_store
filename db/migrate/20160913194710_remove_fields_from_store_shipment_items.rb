class RemoveFieldsFromStoreShipmentItems < ActiveRecord::Migration
  def change
    remove_column :store_shipment_items, :lot
    remove_column :store_shipment_items, :expiration
  end
end

class AddLotToStoreShipmentItems < ActiveRecord::Migration
  def change
    add_column :store_shipment_items, :lot, :string
    add_column :store_shipment_items, :expiration, :integer
  end
end

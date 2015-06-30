class AddFieldsToStoreShipmentItems < ActiveRecord::Migration
  def change
    add_column :store_shipment_items, :product_id, :integer, null: false
    add_column :store_shipment_items, :affiliate_id, :integer
    add_column :store_shipment_items, :variation, :string
  end
end

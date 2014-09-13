class AddSignatureRequiredToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :require_signature, :boolean
    add_column :store_shipments, :insurance, :decimal, precision: 8, scale: 2, null: false, default: false 
  end
end

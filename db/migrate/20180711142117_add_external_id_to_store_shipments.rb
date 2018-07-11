class AddExternalIdToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :external_id, :string
  end
end

class AddItemsHashToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :items_hash, "char(32)"
  end
end

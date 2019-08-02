class AddShipFromNameToStoreShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :store_shipments, :ship_from_name, :string, before: :ship_from_company
  end
end

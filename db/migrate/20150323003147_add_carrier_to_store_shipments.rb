class AddCarrierToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :carrier, :string, after: :recipient_country
  end
end

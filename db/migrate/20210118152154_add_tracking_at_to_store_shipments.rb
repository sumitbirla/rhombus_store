class AddTrackingAtToStoreShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :store_shipments, :tracking_uploaded_at, :datetime, after: :ship_date
  end
end

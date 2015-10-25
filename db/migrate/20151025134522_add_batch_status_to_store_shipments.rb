class AddBatchStatusToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :batch_status, :string
    add_column :store_shipments, :batch_status_message, :string
  end
end

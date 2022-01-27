class AddFulfillerExternalIdToStoreShipments < ActiveRecord::Migration[6.1]
  def change
    add_column :store_shipments, :fulfiller_external_id, :string, after: :fulfiller_notified
  end
end

class AddPaidToStoreShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :store_shipments, :paid, :boolean, null: false, default: false, before: :status
  end
end

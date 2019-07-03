class AddBillingProcessedToStoreShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :store_shipments, :billing_processed, :boolean, null: false, default: false, before: :invoice_amount
  end
end

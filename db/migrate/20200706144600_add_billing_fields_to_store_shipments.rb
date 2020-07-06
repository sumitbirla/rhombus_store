class AddBillingFieldsToStoreShipments < ActiveRecord::Migration[5.2]
  def change
    add_column :store_shipments, :seller_cogs, :decimal, precision: 10, scale: 2
    add_column :store_shipments, :seller_shipping_fee, :decimal, precision: 10, scale: 2
    add_column :store_shipments, :seller_transaction_fee, :decimal, precision: 10, scale: 2
  end
end

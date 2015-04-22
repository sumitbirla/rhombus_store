class AddInvoiceAmountToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :invoice_amount, :decimal, precision: 8, scale: 2
  end
end

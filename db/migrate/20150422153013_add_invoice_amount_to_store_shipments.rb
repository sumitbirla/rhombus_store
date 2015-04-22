class AddInvoiceAmountToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :invoice_amount, :decimal, before: :status
  end
end

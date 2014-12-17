class AddInvoiceIdToStoreShipments < ActiveRecord::Migration
  def change
	add_column :store_shipments, :invoice_id, :integer, after: :fulfilled_by_id
  end
end

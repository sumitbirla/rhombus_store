class AddDomainIdToInvoiceImages < ActiveRecord::Migration
  def change
    add_column :store_invoice_images, :domain_id, :integer, null: false
  end
end

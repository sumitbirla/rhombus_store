class AddArchivedToInvTransactions < ActiveRecord::Migration
  def change
    add_column :inv_transactions, :bulk_import, :boolean, null: false, default: false
    add_column :inv_transactions, :archived, :boolean, null: false, default: false
    remove_column :inv_items, :archived, :boolean
  end
end

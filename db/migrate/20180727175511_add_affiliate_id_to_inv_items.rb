class AddAffiliateIdToInvItems < ActiveRecord::Migration
  def change
    add_column :inv_items, :affiliate_id, :integer, after: :inventory_transaction_id
    add_column :inv_items, :archived, :boolean, after: :cost, null: false, default: false
  end
end

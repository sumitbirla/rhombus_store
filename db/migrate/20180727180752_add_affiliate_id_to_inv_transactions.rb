class AddAffiliateIdToInvTransactions < ActiveRecord::Migration
  def change
    add_column :inv_transactions, :affiliate_id, :integer
    remove_column :inv_items, :affiliate_id, :integer
  end
end

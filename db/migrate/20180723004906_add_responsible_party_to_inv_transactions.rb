class AddResponsiblePartyToInvTransactions < ActiveRecord::Migration
  def change
    add_column :inv_transactions, :responsible_party, :string
  end
end

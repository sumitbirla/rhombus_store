class CreateInventoryTransactions < ActiveRecord::Migration
  def change
    create_table :inv_transactions do |t|
      t.integer :user_id
      t.string :entity_type, null: false
      t.integer :entity_id
      t.text :notes

      t.timestamps null: false
    end

	remove_column :inv_items, :user_id, :integer
	remove_column :inv_items, :transaction_type, :string
	change_column :inv_items, :transaction_id, :integer, null: false
  end
end

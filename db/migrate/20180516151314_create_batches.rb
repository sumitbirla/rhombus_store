class CreateBatches < ActiveRecord::Migration
  def change
    create_table :store_batches do |t|
      t.integer :user_id, null: false
      t.text :notes
      t.string :status, null: false

      t.timestamps null: false
    end
  end
end

class CreateAutoShipItems < ActiveRecord::Migration
  def change
    create_table :store_auto_ship_items do |t|
      t.references :user, index: true, null: false
      t.string :item_id, null: false
      t.references :product, index: true, null: false
      t.references :affiliate, index: true
      t.string :variation
      t.string :description, null: false
      t.integer :quantity, null: false
	  t.integer :days, null: false, default: 30
      t.date :last_shipped
      t.date :next_ship_date

      t.timestamps null: false
    end
  end
end

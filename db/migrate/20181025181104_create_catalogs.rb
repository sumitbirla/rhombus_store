class CreateCatalogs < ActiveRecord::Migration
  def change
    create_table :store_catalogs do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :url

      t.timestamps null: false
    end
  end
end

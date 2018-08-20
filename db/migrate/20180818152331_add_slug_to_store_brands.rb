class AddSlugToStoreBrands < ActiveRecord::Migration
  def change
    add_column :store_brands, :slug, :string, null: false
  end
end

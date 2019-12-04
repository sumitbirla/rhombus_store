class AddSameVariantImagesToStoreProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :store_products, :same_variant_images, :boolean, null: false, default: true
  end
end

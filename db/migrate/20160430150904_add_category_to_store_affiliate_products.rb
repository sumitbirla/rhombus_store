class AddCategoryToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :category1, :string
    add_column :store_affiliate_products, :category2, :string
    add_column :store_affiliate_products, :category3, :string
    add_column :core_affiliates, :price_formula, :string
  end
end

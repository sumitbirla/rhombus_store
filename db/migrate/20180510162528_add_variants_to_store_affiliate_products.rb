class AddVariantsToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :variant1, :string
    add_column :store_affiliate_products, :variant2, :string
  end
end

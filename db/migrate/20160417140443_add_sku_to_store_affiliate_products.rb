class AddSkuToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :sku, :string
	  add_column :store_affiliate_products, :minimum_order_quantity, :integer, null: false, default: 1
  end
end

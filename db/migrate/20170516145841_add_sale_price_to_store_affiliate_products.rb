class AddSalePriceToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :sale_price, :decimal, precision: 10, scale: 4
  end
end

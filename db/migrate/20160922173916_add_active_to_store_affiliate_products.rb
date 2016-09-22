class AddActiveToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :hidden, :boolean, null: false, default: false
  end
end

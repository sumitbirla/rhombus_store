class AddActiveToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :active, :boolean, null: false, default: true
  end
end

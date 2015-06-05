class AddAffiliateOnlyToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :affiliate_only, :boolean, before: :hidden
  end
end

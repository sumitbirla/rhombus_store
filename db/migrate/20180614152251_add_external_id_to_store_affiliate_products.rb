class AddExternalIdToStoreAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :external_id, :string, after: :id
  end
end

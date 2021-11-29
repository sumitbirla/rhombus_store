class AddArchivedToStoreAffiliateProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :store_affiliate_products, :archived, :boolean, null: false, default: false, after: :active
  end
end

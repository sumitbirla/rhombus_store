class AddImagesToAffiliateProducts < ActiveRecord::Migration
  def change
    add_column :store_affiliate_products, :images, :string
  end
end

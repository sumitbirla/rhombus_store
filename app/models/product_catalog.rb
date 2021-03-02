# == Schema Information
#
# Table name: store_product_catalogs
#
#  id                :integer          not null, primary key
#  promotional_price :decimal(10, 4)
#  standard_price    :decimal(10, 4)   not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  catalog_id        :integer          not null
#  product_id        :integer          not null
#
# Indexes
#
#  catalog_id  (catalog_id)
#  product_id  (product_id)
#
class ProductCatalog < ActiveRecord::Base
  self.table_name = "store_product_catalogs"
  belongs_to :product
  belongs_to :catalog

  validates_presence_of :product_id, :catalog_id, :standard_price
end

class ProductCatalog < ActiveRecord::Base
  self.table_name = "store_product_catalogs"
  belongs_to :product
  belongs_to :catalog

  validates_presence_of :product_id, :catalog_id, :standard_price
end

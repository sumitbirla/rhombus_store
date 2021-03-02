# == Schema Information
#
# Table name: store_product_categories
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  product_id  :integer          not null
#
# Indexes
#
#  product_id  (product_id,category_id) UNIQUE
#

class ProductCategory < ActiveRecord::Base
  self.table_name = "store_product_categories"
  belongs_to :product
  belongs_to :category
end

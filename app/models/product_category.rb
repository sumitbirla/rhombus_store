# == Schema Information
#
# Table name: product_categories
#
#  id          :integer          not null, primary key
#  product_id  :integer          not null
#  category_id :integer          not null
#

class ProductCategory < ActiveRecord::Base
  self.table_name = "store_product_categories"
  belongs_to :product
  belongs_to :category
end

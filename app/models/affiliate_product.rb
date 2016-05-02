# == Schema Information
#
# Table name: store_affiliate_products
#
#  id                     :integer          not null, primary key
#  affiliate_id           :integer          not null
#  product_id             :integer          not null
#  sku                    :string(255)
#  price                  :decimal(10, 2)
#  minimum_order_quantity :integer          default("1"), not null
#  title                  :string(255)
#  description            :text(65535)
#  data                   :string(255)
#  images                 :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  category1              :string(255)
#  category2              :string(255)
#  category3              :string(255)
#

class AffiliateProduct < ActiveRecord::Base
  self.table_name = "store_affiliate_products"
  belongs_to :affiliate
  belongs_to :product
  
  validates_uniqueness_of :product_id, scope: :affiliate_id
end

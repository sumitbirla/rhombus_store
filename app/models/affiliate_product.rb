# == Schema Information
#
# Table name: store_affiliate_products
#
#  id           :integer          not null, primary key
#  affiliate_id :integer          not null
#  product_id   :integer          not null
#  price        :decimal(10, 2)
#  title        :string(255)
#  description  :text(65535)
#  data         :string(255)
#  images       :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

class AffiliateProduct < ActiveRecord::Base
  self.table_name = "store_affiliate_products"
  belongs_to :affiliate
  belongs_to :product
  
  validates_uniqueness_of :product_id, scope: :affiliate_id
end

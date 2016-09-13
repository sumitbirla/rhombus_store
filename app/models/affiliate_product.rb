# == Schema Information
#
# Table name: store_affiliate_products
#
#  id                     :integer          not null, primary key
#  affiliate_id           :integer          not null
#  product_id             :integer          not null
#  item_number            :string(255)
#  price                  :decimal(10, 2)
#  minimum_order_quantity :integer          default(1), not null
#  title                  :string(255)
#  description            :text(65535)
#  data                   :string(255)
#  images                 :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  category1              :string(255)
#  category2              :string(255)
#  category3              :string(255)
#  ship_lead_time         :integer          default(14), not null
#

class AffiliateProduct < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_affiliate_products"
  belongs_to :affiliate
  belongs_to :product
  has_many :affiliate_categories
  has_many :categories, -> { order :sort }, through: :affiliate_categories
  
  validates_uniqueness_of :product_id, scope: :affiliate_id
end

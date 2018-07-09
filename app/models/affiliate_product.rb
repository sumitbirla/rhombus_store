# == Schema Information
#
# Table name: store_affiliate_products
#
#  id                     :integer          not null, primary key
#  affiliate_id           :integer          not null
#  item_number            :string(255)
#  product_id             :integer          not null
#  price                  :decimal(10, 4)
#  sale_price             :decimal(10, 4)
#  minimum_order_quantity :integer          default(1), not null
#  title                  :string(255)
#  description            :text(65535)
#  data                   :string(255)
#  images                 :string(255)
#  category1              :string(255)
#  category2              :string(255)
#  category3              :string(255)
#  ship_lead_time         :integer          default(14), not null
#  hidden                 :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#

class AffiliateProduct < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_affiliate_products"
  belongs_to :affiliate
  belongs_to :product
  has_many :affiliate_categories
  has_many :categories, -> { order :sort }, through: :affiliate_categories
  validates :product_id, uniqueness: { scope: :affiliate_id }
  
  def current_price
    sale_price || price || product.special_price || product.price
  end
  
  def sale?
    [sale_price, product.special_price].include?(current_price)
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

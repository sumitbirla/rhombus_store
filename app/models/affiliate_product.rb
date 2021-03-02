# == Schema Information
#
# Table name: store_affiliate_products
#
#  id                     :integer          not null, primary key
#  active                 :boolean          default(TRUE), not null
#  category1              :string(255)
#  category2              :string(255)
#  category3              :string(255)
#  data                   :string(255)
#  description            :text(65535)
#  hidden                 :boolean          default(FALSE), not null
#  images                 :string(255)
#  item_number            :string(255)
#  minimum_order_quantity :integer          default(1), not null
#  price                  :decimal(10, 4)
#  sale_price             :decimal(10, 4)
#  ship_lead_time         :integer          default(5), not null
#  title                  :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  affiliate_id           :integer          not null
#  external_id            :string(255)
#  product_id             :integer          not null
#
# Indexes
#
#  index_affiliate_products_on_affiliate_id  (affiliate_id)
#  index_affiliate_products_on_product_id    (product_id)
#  item_number                               (item_number)
#
# Foreign Keys
#
#  store_affiliate_products_ibfk_1  (product_id => store_products.id)
#

class AffiliateProduct < ActiveRecord::Base
  include Exportable

  self.table_name = "store_affiliate_products"
  belongs_to :affiliate
  belongs_to :product
  has_many :affiliate_categories
  has_many :categories, -> { order :sort }, through: :affiliate_categories
  validates :product_id, uniqueness: {scope: :affiliate_id}

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

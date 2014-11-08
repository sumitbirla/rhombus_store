# == Schema Information
#
# Table name: products
#
#  id                   :integer          not null, primary key
#  group                :string(255)
#  product_type         :string(255)
#  slug                 :string(255)
#  brand_id             :integer
#  title                :string(255)      not null
#  option_title         :string(255)
#  option_sort          :integer
#  sku_id               :integer          not null
#  sku_multiple         :integer          default(1), not null
#  price                :decimal(10, 2)   not null
#  special_price        :decimal(10, 2)
#  dealer_price         :decimal(10, 2)
#  free_shipping        :boolean          default(FALSE), not null
#  tax_exempt           :boolean          default(FALSE), not null
#  hidden               :boolean          default(FALSE), not null
#  featured             :boolean          default(FALSE), not null
#  require_image_upload :boolean          default(FALSE), not null
#  short_description    :text
#  long_description     :text
#  created_at           :datetime
#  updated_at           :datetime
#

class Product < ActiveRecord::Base
  self.table_name = "store_products"
  belongs_to :brand
  belongs_to :affiliate
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfiller_id'
  belongs_to :supplier, class_name: 'Affiliate', foreign_key: 'primary_supplier_id'

  has_many :pictures, -> { order :sort }, as: :imageable
  has_many :comments, as: :commentable
  has_many :product_categories
  has_many :coupons, -> { order 'created_at desc' }
  has_many :categories, -> { order :sort }, through: :product_categories
  has_many :pattributes, class_name: 'ProductAttribute'
  
  validates_presence_of :name, :sku, :title, :slug, :brand_id, :product_type, :price
  validates_uniqueness_of :slug
  
  def to_s
    "#{sku}: #{title}"
  end
  
  def name_with_option
    str = name
    str += ', ' + option_title unless option_title.blank?
    str
  end
  
  def cache_key
    "product:#{slug}"
  end
  
  def attribute(key)
    attributes.find { |attr| attr.key == key }
  end
end

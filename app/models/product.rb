# == Schema Information
#
# Table name: store_products
#
#  id                     :integer          not null, primary key
#  name                   :string(255)      not null
#  group                  :string(255)
#  product_type           :string(255)
#  slug                   :string(255)
#  brand_id               :integer
#  sku                    :string(255)      default(""), not null
#  active                 :boolean          default(TRUE), not null
#  title                  :string(255)      not null
#  option_title           :string(255)
#  option_sort            :integer
#  distributor_price      :decimal(10, 2)
#  retailer_price         :decimal(8, 2)
#  retail_map             :decimal(10, 2)
#  price                  :decimal(10, 2)   not null
#  msrp                   :decimal(10, 2)
#  special_price          :decimal(10, 2)
#  free_shipping          :boolean          default(FALSE), not null
#  tax_exempt             :boolean          default(FALSE), not null
#  hidden                 :boolean          default(FALSE), not null
#  featured               :boolean          default(FALSE), not null
#  auto_ship              :boolean          default(FALSE), not null
#  affiliate_only         :boolean
#  require_image_upload   :boolean          default(FALSE), not null
#  short_description      :text(65535)
#  long_description       :text(65535)
#  keywords               :string(255)
#  warranty               :string(255)
#  primary_supplier_id    :integer
#  fulfiller_id           :integer
#  label_sheet_id         :integer
#  item_length            :decimal(10, 3)
#  item_width             :decimal(10, 3)
#  item_height            :decimal(10, 3)
#  item_weight            :decimal(10, 3)
#  case_length            :decimal(10, 3)
#  case_width             :decimal(10, 3)
#  case_height            :decimal(10, 3)
#  case_weight            :decimal(10, 3)
#  case_quantity          :integer
#  country_of_origin      :string(255)
#  minimum_order_quantity :integer
#  low_threshold          :integer
#  committed              :integer          default(0), not null
#  shipping_lead_time     :integer
#  item_availability      :date
#  created_at             :datetime
#  updated_at             :datetime
#

class Product < ActiveRecord::Base
  self.table_name = "store_products"
  belongs_to :brand
  belongs_to :affiliate
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfiller_id'
  belongs_to :supplier, class_name: 'Affiliate', foreign_key: 'primary_supplier_id'
  belongs_to :label_sheet

  has_many :pictures, -> { order :sort }, as: :imageable
  has_many :comments, as: :commentable
  has_many :product_categories
  has_many :coupons, -> { order 'created_at desc' }
  has_many :categories, -> { order :sort }, through: :product_categories
  has_many :product_attributes
  has_many :pattributes, -> { order :sort }, through: :product_attributes, source: :core_attribute
  
  validates_presence_of :name, :sku, :title, :slug, :brand_id, :product_type, :price
  validates_presence_of :sku2, if: :warehoused?
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
  
  def warehoused?
    product_type == "warehoused"
  end
  
end

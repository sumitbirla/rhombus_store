# == Schema Information
#
# Table name: store_products
#
#  id                   :integer          not null, primary key
#  name                 :string(255)      not null
#  group                :string(255)
#  product_type         :string(255)      default(""), not null
#  slug                 :string(255)
#  brand_id             :integer
#  item_number          :string(255)      default(""), not null
#  upc                  :string(255)
#  sku                  :string(255)
#  active               :boolean          default(TRUE), not null
#  title                :string(255)
#  option_title         :string(255)
#  option_sort          :integer
#  retail_map           :decimal(10, 2)
#  price                :decimal(10, 2)
#  msrp                 :decimal(10, 2)
#  special_price        :decimal(10, 2)
#  free_shipping        :boolean          default(FALSE), not null
#  tax_exempt           :boolean          default(FALSE), not null
#  hidden               :boolean          default(FALSE), not null
#  featured             :boolean          default(FALSE), not null
#  auto_ship            :boolean          default(FALSE), not null
#  affiliate_only       :boolean
#  require_image_upload :boolean          default(FALSE), not null
#  short_description    :text(65535)
#  long_description     :text(65535)
#  keywords             :string(255)
#  warranty             :string(255)
#  fulfiller_id         :integer
#  label_sheet_id       :integer
#  item_length          :decimal(10, 3)
#  item_width           :decimal(10, 3)
#  item_height          :decimal(10, 3)
#  item_weight          :decimal(10, 3)
#  case_length          :decimal(10, 3)
#  case_width           :decimal(10, 3)
#  case_height          :decimal(10, 3)
#  case_weight          :decimal(10, 3)
#  case_quantity        :integer
#  country_of_origin    :string(255)
#  low_threshold        :integer
#  item_availability    :date
#  harmonized_code      :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#

class Product < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_products"
  belongs_to :brand
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfiller_id'
  belongs_to :label_sheet
	belongs_to :template_product, class_name: 'Product'

  has_many :pictures, -> { order :sort }, as: :imageable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :coupons, -> { order 'created_at desc' }, dependent: :destroy
  has_many :categories, -> { order :sort }, through: :product_categories
  has_many :extra_properties, -> { order "sort, name" }, as: :extra_property, dependent: :destroy
  has_many :label_elements, dependent: :destroy
	has_many :order_items, :dependent => :restrict_with_exception
	has_many :affiliate_products, :dependent => :restrict_with_exception
  has_many :shipping_rates, class_name: 'ProductShippingRate'
	
	accepts_nested_attributes_for :shipping_rates, allow_destroy: true,
																reject_if: proc { |a| a["destination_country_code"].blank? || 
																											a["ship_method"].blank? || 
																											a["first_item"].blank? || 
																											a["additional_items"].blank? }
	
  validates_presence_of :name, :item_number, :product_type, :fulfiller_id
  validates_presence_of :title, :slug, :brand_id, :price, unless: lambda { |x| x.product_type == 'white-label' }
  validates_presence_of :sku, if: :warehoused?
	validates_uniqueness_of :item_number
	validates_uniqueness_of :upc, unless: lambda { |x| x.upc.blank? }
  
  def to_s
    "#{sku}: #{title}"
  end
  
  def name_with_option
    str = name
    str += ', ' + option_title unless option_title.blank?
    str
  end
  
  def full_name
    str = name_with_option
    str = brand.name + " " + str unless brand.nil?
    str
  end
	
	# get items have the same group attribute as this product
	def group_items
		@group_items ||= Product.includes(:pictures)
					 									.where(group: group.presence || '_ZZZZ_', active: true, hidden: false)
					 								  .order(:option_sort, :option_title)
	end
	
	
	# assuming long description is in plain text, tries to convert to HTML with bullet points
	def html_description
		paragraphs = long_description.delete("\r").gsub("\n\n", "\n").split("\n")
		str = paragraphs.map { |x| "<p>#{x}</p>" }.join
		
		bullets = []
		(1..5).each do |x| 
			point = get_property("Bullet #{x}")
			bullets << point unless point.blank?
		end
		
		if bullets.length > 0
			str += "<ol>"
			str += bullets.map { |x| "<li>#{x}</li>" }.join
			str += "</ol>"
		end
		
		str
	end
  
  def cache_key
    "product:#{slug}"
  end
  
  def warehoused?
    ["stock", "white-label"].include?(product_type)
  end
  
  def get_property(name)
    a = extra_properties.find { |x| x.name == name }
    a.nil? ? "" : a.value
  end
  
  def set_property(name, value)
    a = extra_properties.find { |x| x.name == name }
    if [true, false].include? value
      value = (value ? "Yes" : "No")
    end
    
    if a.nil?
      self.extra_properties.build(name: name, value: value) unless value.blank?
    else
      if value.blank?
        a.destroy
      else
        a.update(value: value)
      end
    end
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

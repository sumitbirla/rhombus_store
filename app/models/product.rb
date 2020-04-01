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
  self.table_name = "store_products"
  
  before_save :set_group
	before_save :strip_fields
  
  belongs_to :brand
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfiller_id'
  belongs_to :label_sheet
	belongs_to :template_product, class_name: 'Product'

  has_many :pictures, -> { order :sort }, as: :imageable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :coupons, -> { order 'created_at desc' }, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :categories, -> { order :sort }, through: :product_categories
  has_many :product_catalogs, dependent: :destroy
  has_many :catalogs, through: :product_catalogs
  has_many :extra_properties, -> { order "sort, name" }, as: :extra_property, dependent: :destroy
  has_many :label_elements, dependent: :destroy
	has_many :order_items, :dependent => :restrict_with_exception
	has_many :affiliate_products, :dependent => :restrict_with_exception
	has_many :shipping_rates, class_name: "ProductShippingRate"
  
  validates_presence_of :name, :item_number, :product_type, :fulfiller_id
  validates_presence_of :title, :slug, :brand_id, :price, unless: lambda { |x| x.product_type == 'white-label' }
  validates_presence_of :sku, if: :warehoused?
	validates_uniqueness_of :item_number
	validates_uniqueness_of :upc, unless: lambda { |x| x.upc.blank? }
	
	accepts_nested_attributes_for :shipping_rates, reject_if: proc { |sr| sr['destination_country_code'].blank? }
  
  def to_s
    "#{sku}: #{title}"
  end
	
  def self.to_csv(list, opts = {})
  
    CSV.generate do |csv|
      base_cols = [ "item_number", 
										"upc", 
										"sku", 
										"group",
										"brand", 
										"name", 
                    "option_name",
										"option_title", 
										"option_sort",
                    "option2_name",
										"option2_title", 
										"option2_sort",
                    "option3_name",
										"option3_title", 
										"option3_sort", 
										"title", 
										"retail_map", 
										"reseller_price", 
										"price", 
										"msrp",
										"keywords",
										"warranty",
										"label_file",
										"item_length",
										"item_width",
										"item_height",
										"item_weight",
										"case_length",
										"case_width",
										"case_height",
										"case_weight",
										"case_quantity",
										"shipping_code",
										"country_of_origin",
										"harmonized_code",
										"short_description",
										"long_description"
									]

			extra_cols = []
			(1..5).each { |x| extra_cols << "image#{x}_url" }
			(1..10).each do |x| 
				extra_cols << "attr#{x}_name" 
				extra_cols << "attr#{x}_value" 
			end
      csv << base_cols + extra_cols
			
			img_base_url = "http:" + Setting.get(Rails.configuration.domain_id, :system, "Static Files Url")
			
      list.each do |x| 
				h = x.attributes.values_at(*base_cols)
				h[4] = x.brand.name if x.brand
				
				# product photos
				5.times { h << '' }
				x.pictures.each_with_index { |pic, i| h[base_cols.length+i] = img_base_url + pic.file_path }
				
				# extra properties
				x.extra_properties.each { |prop| h += [prop.name, prop.value] }	
				csv << h
			end
			
			
    end
  
  end
  
  def name_with_option
    str = name
    str += ', ' + option_title unless option_title.blank?
    str
  end
  
  def variant_string
    opts = []
    opts << "#{option_name}: #{option_title}"  unless option_title.blank?
    opts << "#{option2_name}: #{option2_title}"  unless option2_title.blank?
    opts << "#{option3_name}: #{option3_title}"  unless option3_title.blank?
    
    str = ""
    str = opts.join(", ") if opts.length > 0
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
    if long_description.nil?
      paragraphs = []
    else
		  paragraphs = long_description.delete("\r").gsub("\n\n", "\n").split("\n")
    end
    
		str = paragraphs.map { |x| "<p>#{x}</p>" }.join
		
		bullets = []
		(1..5).each do |x| 
			point = get_property("Bullet #{x}")
			bullets << point unless point.blank?
		end
		
		if bullets.length > 0
			str += "<ul>"
			str += bullets.map { |x| "<li>#{x}</li>" }.join
			str += "</ul>"
		end
    
    extra_properties.each do |prop|
      next unless prop.name.downcase.start_with?("material")
		  str += "<p><b>#{prop.name}:</b><br>#{prop.value}</p>"
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
  
  def set_group
    self.group = SecureRandom.uuid if group.blank?
  end
  
  def strip_fields
    self.name.strip!
    self.item_number.strip!
    self.sku.strip! unless self.sku.nil?
    self.upc.strip! unless self.upc.nil?
    self.slug.strip! unless self.slug.nil?
    self.shipping_code = "000" if self.shipping_code.blank?
  end
  
  def get_variants
    Product.where(group: group).order("option_sort, option_title")
  end
	
	def negotiated_price(seller_id)
		ba = BillingArrangement.find_by(affiliate_id: fulfiller_id, seller_id: seller_id)

		if ba && ba.percent_of_msrp.present?
			return msrp * 	ba.percent_of_msrp / 100.0
		else
			return reseller_price
		end
	end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

class ProductShippingRate < ActiveRecord::Base
	self.table_name = "store_product_shipping_rates"
  belongs_to :product
	
	validates_presence_of :destination_country_code, :ship_method, :first_item, :additional_items
end

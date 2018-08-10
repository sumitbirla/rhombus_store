class ProductShippingRate < ActiveRecord::Base
	self.table_name = "store_product_shipping_rates"
	
	validates_presence_of :code, :destination_country_code, :ship_method, :first_item, :additional_items
  
  def get_cost(quantity)
    if quantity == 0
      return 0.0
    elsif quantity == 1
      return first_item
    elsif quantity == 2
      return first_item + second_item
    else
      return first_item + second_item + additional_items * (quantity-2)
    end
  end
  
end

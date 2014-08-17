# == Schema Information
#
# Table name: shipping_options
#
#  id                      :integer          not null, primary key
#  name                    :string(255)      not null
#  base_cost               :decimal(10, 2)   not null
#  min_order_amount        :integer
#  max_order_amount        :integer
#  active                  :boolean          not null
#  add_product_attribute   :string(255)
#  international_surcharge :boolean          not null
#  description             :text
#  created_at              :datetime
#  updated_at              :datetime
#

class ShippingOption < ActiveRecord::Base
  self.table_name = "store_shipping_options"
end

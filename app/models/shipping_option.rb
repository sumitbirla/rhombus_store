# == Schema Information
#
# Table name: store_shipping_options
#
#  id                      :integer          not null, primary key
#  domain_id               :integer          not null
#  name                    :string(255)      not null
#  base_cost               :decimal(10, 2)   not null
#  min_order_amount        :decimal(10, 2)
#  max_order_amount        :decimal(10, 2)
#  active                  :boolean          not null
#  add_product_attribute   :string(255)
#  international_surcharge :boolean          not null
#  description             :text(65535)
#  created_at              :datetime
#  updated_at              :datetime
#

class ShippingOption < ActiveRecord::Base
  include Exportable
  self.table_name = "store_shipping_options"
  belongs_to :domain
end

# == Schema Information
#
# Table name: store_product_attributes
#
#  id           :integer          not null, primary key
#  product_id   :integer          not null
#  attribute_id :integer          not null
#  value        :text(65535)      not null
#  created_at   :datetime
#  updated_at   :datetime
#

class ProductAttribute < ActiveRecord::Base
  self.table_name = "store_product_attributes"
  belongs_to :product
  belongs_to :core_attribute, class_name: "Attribute", foreign_key: 'attribute_id'
  
  def to_s
    value
  end
end

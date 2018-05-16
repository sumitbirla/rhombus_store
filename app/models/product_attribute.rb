# == Schema Information
#
# Table name: ProductAttributes
#
#  ProdAttributeID   :integer          not null
#  ProdAttribute     :string(20)
#  ProdAttributeDesc :string(100)
#  MaxLength         :integer
#  SystemType        :boolean          default(FALSE)
#  Mod_Date          :datetime
#  Mod_User          :string(15)
#  AtributeTypeID    :integer
#  ItemDescription   :string(50)
#  InventoryAcctIndx :integer
#  COGAcctIndx       :integer
#  ITMCLSCD          :string(11)
#  PetProduct        :boolean          default(FALSE)
#

class ProductAttribute < ActiveRecord::Base
  self.table_name = "store_product_attributes"
  belongs_to :product
  belongs_to :core_attribute, class_name: "Attribute", foreign_key: 'attribute_id'
  
  def to_s
    value
  end
end

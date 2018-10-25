class Catalog < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_catalogs"
  
  validates_presence_of :name, :code, :standard_price
  validates_uniqueness_of :name, :code
  
  has_many :product_catalogs, dependent: :destroy
  has_many :products, through: :product_catalogs
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

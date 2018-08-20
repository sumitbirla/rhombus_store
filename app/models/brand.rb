# == Schema Information
#
# Table name: store_brands
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  website    :string(255)
#  logo       :string(255)
#  about      :text(65535)
#  created_at :datetime
#  updated_at :datetime
#

class Brand < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_brands"
  has_many :products, :dependent => :restrict_with_exception
  validates_presence_of :name, :slug
  validates_uniqueness_of :name
  
  def to_s
    name
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

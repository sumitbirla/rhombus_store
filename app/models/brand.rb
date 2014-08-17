# == Schema Information
#
# Table name: brands
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  website    :string(255)
#  logo       :string(255)
#  about      :text
#  created_at :datetime
#  updated_at :datetime
#

class Brand < ActiveRecord::Base
  self.table_name = "store_brands"
  
  has_many :products
  validates :name, presence: true
  validates_uniqueness_of :name
  
  def to_s
    name
  end
end

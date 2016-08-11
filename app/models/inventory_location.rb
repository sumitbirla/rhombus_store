# == Schema Information
#
# Table name: store_sublocations
#
#  id          :integer          not null, primary key
#  location_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#  zone        :string(255)      not null
#  aisle       :string(255)
#  bay         :string(255)
#  level       :string(255)
#  section     :string(255)
#  notes       :text(65535)
#

class InventoryLocation < ActiveRecord::Base
  include Exportable
  
  self.table_name = 'inv_locations'
  validates_presence_of :name
  
  def to_s
    name
  end
  
end

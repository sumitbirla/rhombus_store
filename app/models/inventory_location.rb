# == Schema Information
#
# Table name: inv_locations
#
#  id           :integer          not null, primary key
#  name         :string(255)      default(""), not null
#  depth        :integer
#  height       :integer
#  width        :integer
#  large_box    :boolean          default(FALSE), not null
#  heavy_box    :boolean          default(FALSE), not null
#  holding_area :boolean          default(FALSE), not null
#  usable       :boolean          default(TRUE), not null
#  notes        :text(65535)
#  created_at   :datetime
#  updated_at   :datetime
#

class InventoryLocation < ActiveRecord::Base
  include Exportable
	
	establish_connection :inventorydb
  
  self.table_name = 'inv_locations'
  validates_presence_of :name
  
  def to_s
    name
  end
end
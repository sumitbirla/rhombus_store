# == Schema Information
#
# Table name: store_sublocations
#
#  id          :integer          not null, primary key
#  location_id :integer
#  name        :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Sublocation < ActiveRecord::Base
  self.table_name = 'store_sublocations'
  belongs_to :location
  validates_presence_of :location_id, :zone
  
  def to_s
    str = zone
    str += '-' + aisle unless aisle.blank?
    str += '-' + bay unless bay.blank?
    str += '-' + level unless level.blank?
    str += '-' + section unless section.blank?
    str
  end
end

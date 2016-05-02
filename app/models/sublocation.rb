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

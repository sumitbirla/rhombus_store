# == Schema Information
#
# Table name: store_upc
#
#  id          :integer          not null, primary key
#  code        :string(255)
#  item        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  notes       :string(255)      default(""), not null
#  flags       :string(255)
#  image_label :string(255)
#

class Upc < ActiveRecord::Base
  include Exportable
  self.table_name = "store_upc"
  scope :allocated, -> { where("item IS NOT NULL AND item <> ''") }
  scope :unallocated, -> { where("item IS NULL OR item = ''") }
  
  def to_s
    code
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

# == Schema Information
#
# Table name: label_sheets
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  width      :decimal(6, 2)    not null
#  height     :decimal(6, 2)    not null
#  dpi        :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

class LabelSheet < ActiveRecord::Base
  self.table_name = "store_label_sheets"
  has_many :areas, class_name: 'LabelArea'
  
  validates_presence_of :name, :width, :height, :dpi
  
  def to_s
    name
  end
end

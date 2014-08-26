# == Schema Information
#
# Table name: label_areas
#
#  id             :integer          not null, primary key
#  label_sheet_id :integer
#  name           :string(255)      not null
#  top            :decimal(6, 2)    not null
#  left           :decimal(6, 2)    not null
#  width          :decimal(6, 2)    not null
#  height         :decimal(6, 2)    not null
#  created_at     :datetime
#  updated_at     :datetime
#

class LabelArea < ActiveRecord::Base
  self.table_name = "store_label_areas"
  belongs_to :label_sheet
end

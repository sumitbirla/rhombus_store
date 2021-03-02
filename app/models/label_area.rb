# == Schema Information
#
# Table name: store_label_areas
#
#  id             :integer          not null, primary key
#  height         :decimal(6, 3)    not null
#  left           :decimal(6, 3)    not null
#  name           :string(255)      not null
#  top            :decimal(6, 3)    not null
#  width          :decimal(6, 3)    not null
#  created_at     :datetime
#  updated_at     :datetime
#  label_sheet_id :integer
#
# Indexes
#
#  index_label_areas_on_label_sheet_id  (label_sheet_id)
#

class LabelArea < ActiveRecord::Base
  self.table_name = "store_label_areas"
  belongs_to :label_sheet
end

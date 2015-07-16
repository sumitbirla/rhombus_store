# == Schema Information
#
# Table name: store_label_elements
#
#  id                   :integer          not null, primary key
#  product_id           :integer          not null
#  name                 :string(255)      not null
#  type                 :string(255)      not null
#  use                  :string(255)      not null
#  top                  :decimal(6, 2)
#  left                 :decimal(6, 2)
#  width                :decimal(6, 2)
#  height               :decimal(6, 2)
#  background_color     :string(255)
#  horizontal_alignment :string(255)
#  vertical_alignment   :string(255)
#  font_size            :decimal(10, )
#  font_color           :string(255)
#  font_family          :string(255)
#  font_style           :string(255)
#  max_chars            :integer
#  created_at           :datetime
#  updated_at           :datetime
#

class LabelElement < ActiveRecord::Base
  self.table_name = "store_label_elements"
  belongs_to :product
end

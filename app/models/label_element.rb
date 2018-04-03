# == Schema Information
#
# Table name: store_label_elements
#
#  id                   :integer          not null, primary key
#  product_id           :integer          not null
#  name                 :string(255)      not null
#  text_or_image        :string(255)      default(""), not null
#  web_or_print         :string(255)      default(""), not null
#  top                  :integer
#  left                 :integer
#  width                :integer
#  height               :integer
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
  validates_presence_of :name, :text_or_image, :web_or_print, :top, :left, :width, :height
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

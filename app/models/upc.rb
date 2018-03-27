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
  validate :check_digit_valid
  
  def to_s
    code
  end
  
  # Calculate the check digit (last number) based on first 11 number of the UPC code
  def check_digit
    odd = code.each_char.each_slice(2).map(&:first).map(&:to_i).sum
    even = code.slice(0,10).each_char.each_slice(2).map(&:last).map(&:to_i).sum
    res = (odd * 3 + even) % 10
    res = (10 - res) unless res == 0
    res
  end
  
  def check_digit_valid
    errors.add(:code, "Incorrect length") unless code.length == 12
    errors.add(:code, "Check digit is incorrect") unless check_digit == code[11].to_i
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

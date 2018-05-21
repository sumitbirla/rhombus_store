# == Schema Information
#
# Table name: store_batches
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  status      :string(255)      not null
#  start_time  :datetime
#  finish_time :datetime
#  created_at  :datetime         not null
#  notes       :text(65535)
#  updated_at  :datetime         not null
#

class Batch < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_batches"
  has_many :orders
  belongs_to :user
  
  validates_presence_of :user_id, :status
end

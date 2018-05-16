class Batch < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_batches"
  has_many :orders
  belongs_to :user
  
  validates_presence_of :user_id, :status
end

# == Schema Information
#
# Table name: store_manifests
#
#  id               :integer          not null, primary key
#  day              :date             not null
#  carrier          :string(255)      not null
#  shipment_count   :integer
#  batch_id         :string(255)
#  result           :text(65535)
#  status           :string(255)      not null
#  document_url     :string(255)
#  pickup_requested :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Manifest < ActiveRecord::Base
  self.table_name = "store_manifests"

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end

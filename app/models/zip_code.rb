# == Schema Information
#
# Table name: store_zip_codes
#
#  id               :integer          unsigned, not null, primary key
#  city             :string(32)       default(""), not null
#  code             :string(16)       default(""), not null
#  country_code     :string(2)        default(""), not null
#  county           :string(32)       default(""), not null
#  latitude         :decimal(10, 7)
#  longitude        :decimal(10, 7)
#  shipping_taxable :boolean          default(FALSE), not null
#  state_code       :string(2)        default(""), not null
#  tax_rate         :decimal(6, 2)    not null
#

class ZipCode < ActiveRecord::Base
  include Exportable
  self.table_name = "store_zip_codes"
end

# == Schema Information
#
# Table name: store_zip_codes
#
#  id               :integer          not null, primary key
#  code             :string(16)       default(""), not null
#  country_code     :string(2)        default(""), not null
#  state_code       :string(2)        default(""), not null
#  city             :string(32)       default(""), not null
#  county           :string(32)       default(""), not null
#  latitude         :decimal(10, 7)
#  longitude        :decimal(10, 7)
#  tax_rate         :decimal(6, 2)    not null
#  shipping_taxable :boolean          default("0"), not null
#

class ZipCode < ActiveRecord::Base
    self.table_name = "store_zip_codes"
end

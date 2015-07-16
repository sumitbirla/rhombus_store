# == Schema Information
#
# Table name: store_tax_rates
#
#  id               :integer          not null, primary key
#  code             :string(255)      not null
#  country_code     :string(255)      not null
#  state_code       :string(255)      not null
#  city             :string(255)      not null
#  county           :string(255)      not null
#  rate             :decimal(5, 2)    not null
#  shipping_taxable :boolean          not null
#  created_at       :datetime
#  updated_at       :datetime
#

class TaxRate < ActiveRecord::Base
  self.table_name = "store_tax_rates"
end

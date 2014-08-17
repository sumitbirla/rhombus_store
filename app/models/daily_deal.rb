# == Schema Information
#
# Table name: daily_deals
#
#  id                         :integer          not null, primary key
#  region_id                  :integer          not null
#  affiliate_id               :integer
#  affiliate_remittance       :decimal(8, 2)
#  affiliate_paid             :boolean          not null
#  deal_type                  :string(255)      default(""), not null
#  slug                       :string(255)      not null
#  title                      :string(255)      not null
#  start_time                 :datetime         not null
#  end_time                   :datetime         not null
#  voucher_expiration         :datetime
#  original_price             :decimal(8, 2)    not null
#  deal_price                 :decimal(8, 2)    not null
#  shipping_cost              :decimal(6, 2)
#  conditions                 :text
#  description                :text             not null
#  short_tag_line             :string(255)      not null
#  redemption_instructions    :text
#  order_specifications       :text
#  theme                      :string(255)
#  max_sales                  :integer
#  max_per_user               :integer
#  number_sold                :integer          not null
#  countdown_mode             :boolean          not null
#  sales_before_showing_count :integer
#  active                     :boolean          not null
#  featured                   :boolean          not null
#  allow_photo_upload         :boolean          not null
#  facebook_posts             :integer          not null
#  facebook_clicks            :integer          not null
#  created_at                 :datetime
#  updated_at                 :datetime
#

class DailyDeal < ActiveRecord::Base
  self.table_name = "store_daily_deals"
  
  belongs_to :affiliate
  belongs_to :region
  has_many :pictures, as: :imageable
  has_many :daily_deal_items
  has_many :daily_deal_locations
  has_many :locations, through: :daily_deal_locations
  has_many :coupons, -> { order 'created_at desc' }
  has_many :external_coupons
  has_many :daily_deal_categories
  has_many :categories, through: :daily_deal_categories
  
  validates_presence_of :deal_type, :slug, :title, :start_time, :end_time, :original_price, :deal_price, :description
  validates_presence_of :short_tag_line, :max_sales, :number_sold, :region_id
  validates_uniqueness_of :slug
  
  def cache_key
    "daily-deal:#{slug}"
  end
  
  def discount_percent
    (100.0 * (original_price - deal_price) / original_price).floor
  end
  
  def to_s
    short_tag_line
  end
end

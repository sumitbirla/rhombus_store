# == Schema Information
#
# Table name: store_daily_deals
#
#  id                         :integer          not null, primary key
#  active                     :boolean          not null
#  affiliate_paid             :boolean          not null
#  affiliate_remittance       :decimal(8, 2)
#  allow_photo_upload         :boolean          not null
#  conditions                 :text(65535)
#  countdown_mode             :boolean          not null
#  deal_price                 :decimal(8, 2)    not null
#  deal_type                  :string(255)      default(""), not null
#  description                :text(65535)      not null
#  end_time                   :datetime         not null
#  facebook_clicks            :integer          not null
#  facebook_posts             :integer          not null
#  fb_discount                :decimal(5, 2)    default(0.0), not null
#  featured                   :boolean          not null
#  max_per_user               :integer
#  max_sales                  :integer
#  number_sold                :integer          not null
#  order_specifications       :text(65535)
#  original_price             :decimal(8, 2)    not null
#  redemption_instructions    :text(65535)
#  sales_before_showing_count :integer
#  shipping_cost              :decimal(6, 2)    default(0.0), not null
#  short_tag_line             :string(255)      not null
#  slug                       :string(255)      not null
#  start_time                 :datetime         not null
#  theme                      :string(255)
#  title                      :string(255)      not null
#  uuid                       :string(255)      not null
#  voucher_expiration         :datetime
#  created_at                 :datetime
#  updated_at                 :datetime
#  affiliate_id               :integer
#
# Indexes
#
#  index_daily_deals_on_affiliate_id  (affiliate_id)
#

class DailyDeal < ActiveRecord::Base
  include Exportable
  self.table_name = "store_daily_deals"

  belongs_to :affiliate
  belongs_to :region
  has_many :pictures, -> { order 'sort' }, as: :imageable
  has_many :items, class_name: 'DailyDealItem'
  has_many :daily_deal_locations
  has_many :locations, through: :daily_deal_locations
  has_many :coupons, -> { order 'created_at desc' }
  has_many :external_coupons
  has_many :daily_deal_categories
  has_many :categories, through: :daily_deal_categories

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: lambda { |attrs| attrs['product_id'].blank? }
  accepts_nested_attributes_for :locations

  validates_presence_of :deal_type, :slug, :title, :start_time, :end_time, :original_price, :deal_price, :description
  validates_presence_of :short_tag_line, :max_sales, :number_sold, :affiliate_id
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

  def orders
    Order.includes(:items).where.not(status: 'in cart').where(id: OrderItem.where(daily_deal_id: id).pluck(:order_id)).order(submitted: :desc)
  end

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end

end

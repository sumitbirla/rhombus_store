class Admin::Inventory::ReportsController < Admin::BaseController
  skip_before_action :verify_authenticity, raise: false
  before_action :set_report_params

  def index
  end

  def pending_fulfillment

    sql = <<-EOF
      select oi.item_number, p.id, p.name, p.option_title, a.name, sum(quantity), s.name, s.id
      from store_order_items oi
      join store_orders o on oi.order_id = o.id
      join store_products p on oi.product_id = p.id
      join core_affiliates a on a.id = oi.affiliate_id
      left join store_label_sheets s on p.label_sheet_id = s.id
      where o.status in ('unshipped', 'submitted')
      group by oi.item_number;
    EOF

    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
  end

  def current_stock

    sql = <<-EOF
      select p.id as product_id, p.sku, p.name, p.option_title, p.price as 'retail_price', sum(i.quantity) as 'quantity', 
        aff.id as 'supplier_id', aff.name as 'supplier_name', ap.price as 'supplier_price'
      from store_inventory_transaction_items i
      join store_products p on p.item_number = i.sku
      left join core_affiliates aff on aff.id = p.primary_supplier_id
      left join store_affiliate_products ap on ap.affiliate_id = aff.id and ap.product_id = p.id 
      group by sku
      order by sku;
    EOF

    @data = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @data << row.symbolize_keys! }
  end

  def inventory_required

    sql = <<-EOF
      select p.id, p.sku, p.name, p.option_title, sum(quantity), s.name, s.id
      from store_order_items oi
      join store_orders o on oi.order_id = o.id
      join store_products p on oi.product_id = p.id
      left join store_label_sheets s on p.label_sheet_id = s.id
      where o.status in ('unshipped', 'submitted')
      group by oi.product_id
      order by sum(quantity) desc;
    EOF

    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
  end


  def set_report_params
    @start_date = params[:start_date] || 2.months.ago.strftime("%Y-%m-%d")
    @end_date = params[:end_date] || 1.day.from_now.strftime("%Y-%m-%d")
  end

end
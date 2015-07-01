class Admin::Store::ReportsController < Admin::BaseController
  skip_before_filter :verify_authenticity
  before_filter :set_report_params
  
  def index
  end
  
  def product_sales
    
    sql = <<-EOF
      select o.sales_channel, item_id, CONCAT(p.name, ' ', p.option_title), sum(quantity), unit_price, sum(quantity) * unit_price 
      from store_order_items i 
      join store_orders o on o.id = i.order_id
      join store_products p on i.product_id = p.id
      where o.status in ('submitted', 'completed', 'shipped', 'unshipped')
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by o.sales_channel, item_id
      order by sum(quantity) desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
    
  end
  
  def user_leaderboard
    
    sql = <<-EOF
      select shipping_name, user_id, count(id), sum(total)
      from store_orders
      where status in ('submitted', 'completed', 'shipped', 'unshipped')
      and submitted > '#{@start_date}' and submitted < '#{@end_date}'
      and sales_channel LIKE '#{@selected_channel}'
      group by notify_email
      order by count(id) desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
    
  end
  
  def purchase_frequency
    
    sql = <<-EOF
      select order_count, count(*) as num_users
      from (select shipping_name, COUNT(*) as order_count 
      	  from store_orders 
          where status in ('submitted', 'completed', 'shipped', 'unshipped')
          and submitted > '#{@start_date}' and submitted < '#{@end_date}'
          and sales_channel LIKE '#{@selected_channel}'
      	  group by notify_email) as dt
      group by order_count
      order by order_count desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
  end
  
  def daily_sales
    
    sql = <<-EOF
      select date(submitted), count(*), sum(total)
      from store_orders
      where submitted IS NOT NULL and status in ('shipped', 'completed', 'unshipped', 'submitted')
      and submitted > '#{@start_date}' and submitted < '#{@end_date}'
      and sales_channel LIKE '#{@selected_channel}'
      group by date(submitted)
      order by date(submitted) desc;
    EOF
  
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row } 
  end
  
  
  def monthly_sales
    
    @start_date = params[:start_date] || 6.months.ago.strftime("%Y-%m-%d")
    
    sql = <<-EOF
      select submitted, count(*), sum(total)
      from store_orders
      where submitted IS NOT NULL and status in ('shipped', 'completed', 'unshipped', 'submitted')
      and submitted > '#{@start_date}' and submitted < '#{@end_date}'
      and sales_channel LIKE '#{@selected_channel}'
      group by year(submitted), month(submitted)
      order by date(submitted) desc;
    EOF
  
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row } 
  end
  
  
  def pending_fulfillment
    
    sql = <<-EOF
      select oi.item_id, p.id, p.name, p.option_title, a.name, sum(quantity), s.name, s.id
      from store_order_items oi
      join store_orders o on oi.order_id = o.id
      join store_products p on oi.product_id = p.id
      join core_affiliates a on a.id = oi.affiliate_id
      left join store_label_sheets s on p.label_sheet_id = s.id
      where o.status in ('unshipped', 'submitted')
      group by oi.item_id;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row } 
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
    
    @sales_channels = Order.uniq(:sales_channel).pluck(:sales_channel)
    @selected_channel = '%'
    @selected_channel = params[:sales_channel] unless params[:sales_channel].blank?
    @start_date = params[:start_date] || 2.months.ago.strftime("%Y-%m-%d")
    @end_date = params[:end_date] || '2018-1-1'
    
  end
  
end
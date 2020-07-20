class Admin::Store::ReportsController < Admin::BaseController
  skip_before_action :verify_authenticity, raise: false
  before_action :set_report_params
  
  def index
  end
  
  def product_sales
    
    sql = <<-EOF
      select o.sales_channel, i.item_number, CONCAT(p.name, ' ', p.option_title), sum(quantity), unit_price, sum(quantity) * unit_price 
      from store_order_items i 
      join store_orders o on o.id = i.order_id
      join store_products p on i.product_id = p.id
      where o.status in ('submitted', 'completed', 'shipped', 'unshipped')
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by #{@group_channel} item_number
      order by sum(quantity) desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
    
  end
  
  def product_sales_by_sku
    
    sql = <<-EOF
      select o.sales_channel, p.id, p.item_number, sum(oi.quantity), sum(oi.unit_price * oi.quantity), oi.item_description 
      from store_orders o, store_order_items oi, store_products p
      where oi.order_id = o.id
      and oi.product_id = p.id 
      and o.status = 'shipped' 
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by #{@group_channel} product_id
      order by sum(oi.quantity) desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
    
  end
  
  def product_sales_by_user
    
    sql = <<-EOF
      select distinct o.user_id, u.`name`, o.shipping_city, o.shipping_state, oi.item_number, sum(oi.quantity) as 'total_quantity_ordered', 
      avg(o.total) as 'average_order_amount', DATE(o.submitted) as 'last ordered', u.email 
      from store_orders o
      join store_order_items oi on oi.order_id = o.id
      join core_users u on o.user_id = u.id
      where oi.product_id = #{params[:product_id]}
      and o.status = 'shipped'
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by o.user_id
      order by sum(oi.quantity) desc, o.submitted DESC;
    EOF
    
    puts sql
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row }
    
  end
  
  def product_sales_by_affiliate
    
    sql = <<-EOF
      select sales_channel, a.code, name, sum(quantity), a.name, a.id 
      from store_shipment_items si, store_shipments s, store_orders o, core_affiliates a
      where si.shipment_id = s.id 
      and si.affiliate_id IS NOT NULL
      and s.order_id = o.id
      and si.affiliate_id = a.id
      and s.status = 'shipped'
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by #{@group_channel} si.affiliate_id
      order by sum(`quantity`) desc;
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
      group by user_id
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
      	  group by user_id) as dt
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
      where submitted IS NOT NULL
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
      where submitted IS NOT NULL
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
      select oi.item_number, p.id, p.name, p.option_title, '', sum(quantity), s.name, s.id
      from store_order_items oi
      join store_orders o on oi.order_id = o.id
      join store_products p on oi.product_id = p.id
      left join store_label_sheets s on p.label_sheet_id = s.id
      where o.status in ('backordered', 'awaiting_shipment')
      group by oi.item_number;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row } 
  end
  
  def current_stock
    
    sql = <<-EOF
      select p.id as product_id, p.sku, p.name, p.option_title, sum(i.quantity) as 'quantity', loc.name as 'location' 
      from inv_items i
      join store_products p on p.item_number = i.sku
      join inv_locations loc on loc.id = i.inventory_location_id
      group by i.sku, i.inventory_location_id having sum(i.quantity) > 0
      order by i.sku;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @data << row.symbolize_keys!} 
  end
  
  def inventory_required
    
    sql = <<-EOF
      select p.id, p.sku, p.name, p.option_title, sum(quantity), s.name, s.id
      from store_order_items oi
      join store_orders o on oi.order_id = o.id
      join store_products p on oi.product_id = p.id
      left join store_label_sheets s on p.label_sheet_id = s.id
      where o.status in ('backordered', 'awaiting_shipment')
      group by oi.product_id
      order by sum(quantity) desc;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data << row } 
    
    @inventory = InventoryItem.where(sku: @data.map { |x| x[1]} )
                              .group(:sku).select("sku, sum(quantity) as quantity")
  end
  
  
  
  def sales_trend
    
    sql = <<-EOF
      select p.id, sum(oi.quantity)
      from store_orders o, store_order_items oi, store_products p
      where o.id = oi.order_id
      and oi.product_id = p.id
      and o.status in ('shipped', 'submitted', 'backordered')
      and o.submitted > NOW() - INTERVAL 1 WEEK
      group by p.id;
    EOF

    @data_1wk = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data_1wk << row } 

    sql = <<-EOF
      select p.id, sum(oi.quantity)
      from store_orders o, store_order_items oi, store_products p
      where o.id = oi.order_id
      and oi.product_id = p.id
      and o.status in ('shipped', 'submitted', 'backordered')
      and o.submitted > NOW() - INTERVAL 2 WEEK
      group by p.id;
    EOF

    @data_2wk = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data_2wk << row } 

    sql = <<-EOF
      select p.id, sum(oi.quantity) 
      from store_orders o, store_order_items oi, store_products p
      where o.id = oi.order_id
      and oi.product_id = p.id
      and o.status in ('shipped', 'submitted', 'backordered')
      and o.submitted > NOW() - INTERVAL 1 MONTH
      group by p.id;
    EOF

    @data_1mo = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data_1mo << row } 

    sql = <<-EOF
      select p.id, sum(oi.quantity)
      from store_orders o, store_order_items oi, store_products p
      where o.id = oi.order_id
      and oi.product_id = p.id
      and o.status in ('shipped', 'submitted', 'backordered')
      and o.submitted > NOW() - INTERVAL 3 MONTH
      group by p.id;
    EOF

    @data_3mo = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data_3mo << row } 

    sql = <<-EOF
      select p.id, p.sku, CONCAT(p.name, ', ', p.option_title), sum(oi.quantity)
      from store_orders o, store_order_items oi, store_products p
      where o.id = oi.order_id
      and oi.product_id = p.id
      and o.status in ('shipped', 'submitted', 'backordered')
      and o.submitted > NOW() - INTERVAL 6 MONTH
      group by p.id;
    EOF

    @data_6mo = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @data_6mo << row } 
    
    sql = <<-EOF
      select p.id, coalesce(sum(i.quantity), 0)
      from store_products p
      left join inv_items i on p.sku = i.sku
      group by p.sku;
    EOF
    
    @stock = []
    ActiveRecord::Base.connection.execute(sql).each { |row| @stock << row }
    
  end
	
	
  def shipments
    
    sql = <<-EOF
		select aff.id as affiliate_id, aff.name as affiliate_name, shp.status, count(shp.status) as total
		from store_shipments shp
		join core_affiliates aff on aff.id = shp.fulfilled_by_id
		where shp.created_at > '#{@start_date}' and shp.created_at < '#{@end_date}'
		group by shp.fulfilled_by_id, shp.status;
    EOF
    
    @data = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @data << row } 
  
  end
  
  
  
  
  def set_report_params
    
    @sales_channels = Order.distinct(:sales_channel).pluck(:sales_channel)
    @selected_channel = '%'
    @group_channel = ''
    unless params[:sales_channel].blank?
      @selected_channel = params[:sales_channel]
      @group_channel = "sales_channel, "
    end
    
    @start_date = params[:start_date] || 2.months.ago.strftime("%Y-%m-%d")
    @end_date = params[:end_date] || 1.day.from_now.strftime("%Y-%m-%d")
    
  end
  
end
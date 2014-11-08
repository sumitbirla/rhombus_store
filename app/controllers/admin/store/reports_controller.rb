class Admin::Store::ReportsController < Admin::BaseController
  skip_before_filter :verify_authenticity
  
  def index
  end
  
  def product_sales
    @sales_channels = Order.uniq(:sales_channel).pluck(:sales_channel)
    @selected_channel = '%'
    @selected_channel = params[:sales_channel] unless params[:sales_channel].blank?
    @start_date = params[:start_date] || '2014-1-1'
    @end_date = params[:end_date] || '2018-1-1'
        
    sql = <<-EOF
      select o.sales_channel, item_id, CONCAT(p.name, ' ', p.option_title), sum(quantity), unit_price, sum(quantity) * unit_price 
      from store_order_items i 
      join store_orders o on o.id = i.order_id
      join store_products p on i.product_id = p.id
      where o.status in ('submitted', 'completed', 'shipped')
      and o.submitted > '#{@start_date}' and o.submitted < '#{@end_date}'
      and o.sales_channel LIKE '#{@selected_channel}'
      group by o.sales_channel, item_id
      order by sum(quantity) desc;
    EOF
    
    conn = ActiveRecord::Base.connection
    
    @data = []
    conn.execute(sql).each do |row|
      @data << row 
    end
  end
  
end
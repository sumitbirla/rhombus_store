namespace :rhombus_store do
  
  
  desc "Create shipments (or mark as backordered) for newly submitted orders"
  task create_shipments: :environment do 
    
    Order.where(status: [:backordered, :submitted]).order(:submitted).each do |o|
  	  next if Cache.setting(o.domain_id, :shipping, "Auto Create Shipment") != "true"
      next if o.shipments.count > 0
      
      begin
  		  o.create_shipment(nil)
        o.update_attribute(:status, :awaiting_shipment)
      rescue => e
        Rails.logger.info e.message
        o.update_attribute(:status, :backordered)
      end
    end
      
  end
  
  
  desc "Process auto-ship items and create orders"
  task auto_ship_items: :environment do
    @logger = Logger.new(Rails.root.join("log", "autoship.log"))
    
    asi_list = AutoShipItem.where(status: :active).where("next_ship_date < ?", Date.today + 2.day)
    user_ids = asi_list.pluck(:user_id).uniq
    
    user_ids.each do |user_id|
      begin
        create_order(asi_list, user_id) 
      rescue => e
        @logger.error e
      end
    end
  end
  
  
  def create_order(asi_list, user_id)
    
    prev_order = Order.where(status: :shipped, user_id: user_id).last
    if prev_order.nil?
      AutoShipItem.where(user_id: user_id).update_all(status: :missing_order)
      @logger.error "No order for UserID: #{user_id} found.  Skipping."
      return
    end
    
    new_order = prev_order.dup
    
    new_order.assign_attributes(
      submitted: DateTime.now,
      status: :payment_pending,
      payment_method: 'CREDIT_CARD',
      auto_ship: true,
      external_order_id: nil,
      ship_earliest: Date.today,
      payment_due: nil,
      cc_type: nil,
      cc_number: nil,
      cc_code: nil,
      cc_expiration_month: nil,
      cc_expiration_year: nil,
      paypal_token: nil,
      cart_key: ''
    )
    new_order.save(validate: false)
    
    items = asi_list.where(user_id: user_id)
    
    items.each do |i|
      p = Product.find(i.product_id)
      
      OrderItem.create(
        order_id: new_order.id,
        item_number: i.item_number,
        product_id: i.product_id,
        affiliate_id: i.affiliate_id,
        variation: i.variation,
        item_description: i.description,
        quantity: i.quantity,
        quantity_accepted: i.quantity,
        unit_price: p.price
      )
    end

    # update autoship items
    items.each do |asi|
      num_days = (asi.next_ship_date - asi.last_shipped).to_i + 2
      asi.last_shipped = Date.today
      asi.next_ship_date = Date.today + num_days.days
      asi.save
    end

    @logger.info "New order ##{new_order.id} created."
    
  end
  
  
  desc "Invoice purchase orders that were shipped today"
  task create_invoices: :environment do
    @logger = Logger.new(Rails.root.join("log", "invoice.log"))
    
    shipments = Shipment.joins(:order)
            .joins(order: :affiliate)
            .includes(:items, :order)
            .where(status: :shipped, ship_date: Date.today)
            .where("store_orders.sales_channel = ?", "Purchase Order")
            .order("store_orders.affiliate_id, store_orders.external_order_id")
            
    prev_affiliate_id = nil
    invoice = nil
    
    shipments.each do |s|
      
    end
    
  end
  

end

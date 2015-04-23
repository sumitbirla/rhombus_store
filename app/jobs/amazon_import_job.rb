require "peddler"

class AmazonImportJob < ActiveJob::Base
  queue_as :default
  
  # reschedule job
  after_perform do |job|
    self.class.set(wait: 600).perform_later
  end

  def perform(*args)
    @logger = Logger.new(Rails.root.join("log", "amazon.log"))
    @client = MWS.orders(
          marketplace_id: 'ATVPDKIKX0DER',
          merchant_id: 'A2MPCZD8121NJH',
          aws_access_key_id: 'AKIAIIBDZMGLHXCEZRIA',
          aws_secret_access_key: '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')
          
    parser = @client.list_orders({ created_after: 1.week.ago.iso8601 })

    parser.parse["Orders"]["Order"].each do |o|
      begin
        process_order(o)
      rescue => e
        @logger.error o.inspect
        @logger.error e
      end
    end

  end

  
  def process_order(o)
    return if o["OrderStatus"] == "Pending"

    db_order = Order.find_by(external_order_id: o["AmazonOrderId"])
    if db_order.nil?
      order_items =  @client.list_order_items(o["AmazonOrderId"]).parse["OrderItems"]

      total = 0.0
      total = o["OrderTotal"]["Amount"] unless o["OrderTotal"].nil?

      order = Order.new(
          domain_id: 1,
          external_order_id: o["AmazonOrderId"],
          submitted: Time.iso8601(o["PurchaseDate"]),
          shipping_method: o["ShipmentServiceLevelCategory"],
          notify_email: o["BuyerEmail"],
          billing_name: o["BuyerName"],
          status: o["OrderStatus"].downcase,
          sales_channel: o["SalesChannel"],
          total: total)

      saddr = o["ShippingAddress"]
      unless saddr.nil?
        order.assign_attributes(
          shipping_name: saddr["Name"],
          shipping_street1: saddr["AddressLine1"],
          shipping_street2: saddr["AddressLine2"],
          shipping_state: saddr["StateOrRegion"],
          shipping_city: saddr["City"],
          shipping_zip: saddr["PostalCode"],
          shipping_country: saddr["CountryCode"],
          contact_phone: saddr["Phone"]
        )
      end

      order.save!
      @logger.debug "#{order.id} : #{order.external_order_id} : #{order.status} : #{order.billing_name}"
      
      return if order_items.nil?

      order_items.each do |oi|
        item = oi[1]  # weird
        next if item.nil?
        #ap item, indent: -2

        product = Product.find_by(sku: item["SellerSKU"])
        affiliate_id = nil
        variation = nil
        if product.nil?
          sku, aff_code, variation = item["SellerSKU"].split('-')
          product = Product.find_by(sku: sku)
          next if product.nil?
          affiliate_id = Affiliate.find_by(code: aff_code).id
        end

        begin
          oi = OrderItem.new({
            order_id: order.id,
            product_id: product.id,
            affiliate_id: affiliate_id,
            variation: variation,
            item_id: item["SellerSKU"],
            item_description: item["Title"],
            quantity: item["QuantityOrdered"],
            unit_price: item["ItemPrice"]["Amount"].to_f / item["QuantityOrdered"].to_f,
            external_id: item["OrderItemId"]
          })
          oi.save
        rescue => e
          @logger.error o.inspect, item.inspect
          @logger.error e
        end

        order.update(shipping_cost: item["ShippingPrice"]["Amount"].to_f) unless item["ShippingPrice"].nil?
      end

    else
      updated_str = ""
      updated_str = "(updated)" unless o["OrderStatus"].downcase == db_order.status
      @logger.debug "#{db_order.id} : #{db_order.external_order_id} : #{db_order.status} : #{db_order.billing_name} #{updated_str}"
      db_order.update_attribute(:status, o["OrderStatus"].downcase)
    end
  end
    
end

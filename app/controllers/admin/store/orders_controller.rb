class Admin::Store::OrdersController < Admin::BaseController
  
  def index
    @orders = Order.where(status: params[:status] || Order.valid_statuses).order(submitted: :desc)
    
    q = params[:q]
    unless q.nil?
      if q.to_i == 0
        @orders = @orders.where("billing_name LIKE '%#{q}%' OR shipping_name LIKE '%#{q}%'")
      else
        @orders = @orders.where(id: q)
      end
    end
    
    respond_to do |format|
      format.html { @orders = @orders.includes(:user).page(params[:page]) }
      format.csv { send_data @orders.to_csv }
    end

  end

  def new
    @order = Order.new
    5.times { @order.items.build }
    
    render 'edit'
  end

  def create
    @order = Order.new(order_params)
    @order.submitted = DateTime.now
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @order.items.length + 5 
      count.times { @order.items.build }
      return render 'edit'
    end
  
    if @order.save
      redirect_to action: 'index', notice: 'Order was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @order = Order.includes(:items, [items: :product], [items: :affiliate], :history, [history: :user]).find(params[:id])
  end

  def edit
    @order = Order.find(params[:id])
    2.times { @order.items.build }
  end

  def update
    @order = Order.find(params[:id])
    item_count = @order.items.length

    @order.attributes = order_params
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - item_count + 5 
      count.times { @order.items.build }
      return render 'edit'
    end

    if @order.save(validate: false)
      redirect_to action: 'show', id: @order.id, notice: 'Order was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    redirect_to action: 'index', notice: 'Order has been deleted.'
  end


  def resend_email
    @order = Order.find(params[:id])

    begin
      OrderMailer.order_submitted(@order, session[:user_id]).deliver_now
      flash[:notice] = "Order confirmation has been emailed to #{@order.notify_email}"
    rescue => e
      flash[:notice] = e.message
    end

    redirect_to :back
  end

  def print_shipping_label
    oh = OrderHistory.find(params[:order_history_id])
    if oh.data2 == "PDF"
      return send_data oh.data1, filename: 'label.pdf', type: 'application/pdf'
    else
      begin
        ip_addr = Cache.setting('Shipping', 'Thermal Printer IP')
        s = TCPSocket.new(ip_addr, 9100)
        s.send oh.data1, 0
        s.close

        flash[:info] = "Label send to thermal printer at #{ip_addr}"
      rescue Exception => e
        flash[:error] = e.message
      end
    end

    redirect_to :back
  end


  def receipt
    @order = Order.find(params[:id])
    OrderHistory.create(order_id: @order.id, 
                        user_id: session[:user_id], 
                        event_type: :receipt_print,
                        system_name: 'Rhombus',
                        comment: "Printed receipt")
                        
    render 'receipt', layout: false
  end
  

  def product_labels
    @order = Order.find(params[:id])
  end
  
  
  def update_status
    orders = Order.where(id: params[:order_id]).where.not(status: params[:status])
    orders.each do |o|
      
      if o.status != params[:status]
        
        o.update_attribute(:status, params[:status])
        OrderHistory.create(order_id: o.id, 
                            user_id: session[:user_id], 
                            event_type: :status_update,
                            system_name: 'Rhombus',
                            data1: params[:status],
                            comment: "Status updated to '#{params[:status]}'")
      end
      
    end
    
    flash[:info] = "Status of #{orders.length} order(s) updated to '#{params[:status]}'"
    redirect_to :back
  end
  
  
  def print_receipts
    urls = ''
    token = Cache.setting('System', 'Security Token')
    website_url = Cache.setting('System', 'Website URL')
    
    Order.where(id: params[:order_id]).each do |o|
      digest = Digest::MD5.hexdigest(o.id.to_s + token) 
      urls += " " + website_url + receipt_admin_store_order_path(o, digest: digest) 
      
      OrderHistory.create(order_id: o.id, 
                          user_id: session[:user_id], 
                          event_type: :invoice_print,
                          system_name: 'Rhombus',
                          comment: "Printed invoice")
    end
    
    system "wkhtmltopdf -q #{urls} /tmp/receipts.pdf"
    send_file "/tmp/receipts.pdf"
  end
  
  
  def address_label
    ip_address = Cache.setting('Shipping', 'Thermal Printer IP')
    website_url = Cache.setting('System', 'Website URL')
    orders = Order.where(id: params[:order_id]).where.not(status: params[:status])
  
    begin
      orders.each do |o|
        data = <<-EOF

N
q812
Q609,26
A30,46,0,3,1,1,N,"HEALTHY BREEDS"
A30,72,0,3,1,1,N,"180 DOUGLAS RD E."
A30,98,0,3,1,1,N,"OLDSMAR FL 34677"
B540,46,0,3,2,5,50,B,"#{o.id}"
LO0,170,812,2
A100,250,0,4,1,1,N,"SHIP"
A100,285,0,4,1,1,N,"TO:"
A220,250,0,4,1,1,N,"#{o.shipping_name.upcase}"
A220,290,0,4,1,1,N,"#{o.shipping_street1.upcase}#{"," + o.shipping_street2 unless o.shipping_street2.blank?}"
A220,330,0,4,1,1,N,"#{o.shipping_city.upcase}, #{o.shipping_state} #{o.shipping_zip}"
B220,400,0,P,,N,10,N,"#{o.shipping_zip}"
LO0,480,812,2
A30,500,0,2,1,1,N,"#{website_url}"
A580,500,0,2,1,1,N,""
P1,1
EOF

        s = TCPSocket.new(ip_address, 9100)
        s.send data, 0
        s.close
        
        OrderHistory.create(order_id: o.id, 
                            user_id: session[:user_id], 
                            event_type: :address_label_print,
                            system_name: 'Rhombus',
                            comment: "Address label printed at #{ip_address}")
      end
      
      flash[:info] = "#{orders.length} labels sent to thermal printer at #{ip_address}"
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to :back
  end
  
  
  def send_confirmation
      orders = Order.includes(:items).where(id: params[:order_id])
      count = 0
      
      begin
        orders.each do |o| 
          unless o.notify_email.blank?
            OrderMailer.order_submitted(o, session[:user_id]).deliver_now
            count += 1
          end
        end
        flash[:info] = "#{count} notifications sent."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to :back
  end
  
  def create_shipment
    orders = Order.includes(:shipments).where(id: params[:order_id])
    count = 0
    
    orders.each do |o|
      if o.shipments.length == 0
        shipment = o.create_shipment
        count += 1
        OrderHistory.create(order_id: o.id, user_id: current_user.id, event_type: :shipment_created,
                      system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}")                  
      end
    end
    
    flash[:info] = "#{count} new shipments created"
    redirect_to :back           
  end
  
  def clone
    order = Order.find(params[:id])
    new_order = order.dup
    
    new_order.assign_attributes({
      submitted: DateTime.now,
      status: 'submitted',
      payment_method: '',
      cc_type: nil,
      cc_number: nil,
      cc_code: nil,
      cc_expiration_month: nil,
      cc_expiration_year: nil,
      paypal_token: nil
    })
    new_order.save
    
    order.items.each { |x| new_order.items << x.dup }
    redirect_to action: 'edit', id: new_order.id
  end
  
  
  private
  
    def order_params
      params.require(:order).permit!
    end
  
end

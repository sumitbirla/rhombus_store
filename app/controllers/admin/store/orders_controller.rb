class Admin::Store::OrdersController < Admin::BaseController
  
  def index
    @orders = Order.where(status: Order.valid_statuses).order(submitted: :desc)

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
    render 'edit'
  end

  def create
    @order = Order.new(order_params)
  
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
    5.times { @order.items.build }
  end

  def update
    @order = Order.find(params[:id])
    @order.attributes = order_params

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
      OrderMailer.order_submitted_email(@order).deliver
      flash[:notice] = "Order confirmation has been emailed to #{@order.notify_email}"
    rescue Exception => e
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


  def invoice
    @order = Order.find(params[:id])
    OrderHistory.create(order_id: @order.id, 
                        user_id: session[:user_id], 
                        event_type: :invoice_print,
                        system_name: 'Rhombus',
                        comment: "Printed invoice")
                        
    render 'invoice', layout: false
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
  
  
  def create_invoice
    urls = ''
    token = Cache.setting('System', 'Security Token')
    website_url = Cache.setting('System', 'Website URL')
    
    Order.where(id: params[:order_id]).each do |o|
      digest = Digest::MD5.hexdigest(o.id.to_s + token) 
      urls += " " + website_url + invoice_admin_store_order_path(o, digest: digest) 
      
      OrderHistory.create(order_id: o.id, 
                          user_id: session[:user_id], 
                          event_type: :invoice_print,
                          system_name: 'Rhombus',
                          comment: "Printed invoice")
    end
    
    system "wkhtmltopdf -q #{urls} /tmp/invoices.pdf"
    send_file "/tmp/invoices.pdf"
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

      begin
        orders.each do |o| 
          unless o.notify_email.blank?
            OrderMailer.order_submitted_email(o).deliver 
            OrderHistory.create(order_id: o.id, 
                                user_id: session[:user_id], 
                                event_type: :confirmation_email,
                                system_name: 'Rhombus',
                                comment: "Confirmation email sent to '#{o.notify_email}'")
          end
        end
        flash[:info] = "#{orders.length} notifications sent."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to :back
  end
  
  def create_shipment
    
    orders = Order.includes(:items).where(id: params[:order_id])
    orders.each do |o|
      shipment = o.create_shipment
      OrderHistory.create order_id: o.id, user_id: current_user.id, event_type: :shipment_created,
                      system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}"
    end
    
    flash[:info] = "#{orders.length} new shipments created"
    redirect_to controller: 'admin/store/shipments'
                    
  end
  
  
  private
  
    def order_params
      params.require(:order).permit!
    end
  
end

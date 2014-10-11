class Admin::Store::OrdersController < Admin::BaseController
  
  def index
    @orders = Order.where(status: Order.valid_statuses).includes(:user, :shipments).order(submitted: :desc).page(params[:page])

    q = params[:q]
    unless q.nil?
      if q.to_i == 0
        @orders = @orders.where("billing_name LIKE '%#{q}%' OR shipping_name LIKE '%#{q}%'")
      else
        @orders = @orders.where(id: q)
      end
    end

  end

  def new
    @order = Order.new name: 'New order'
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
  end

  def update
    @order = Order.find(params[:id])
    @order.attributes = order_params

    if @order.save(validate: false)
      redirect_to action: 'index', notice: 'Order was successfully updated.'
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
    website_url = Cache.setting('System', 'Website URL') + "/"
    
    Order.where(id: params[:order_id]).each do |o|
      digest = Digest::MD5.hexdigest(o.id.to_s + token) 
      urls += " " + website_url + invoice_admin_store_order_path(o, digest: digest) 
    end
    
    system "wkhtmltopdf #{urls} /tmp/invoices.pdf"
    send_file "/tmp/invoices.pdf"
  end
  
  
  private
  
    def order_params
      params.require(:order).permit!
    end
  
end

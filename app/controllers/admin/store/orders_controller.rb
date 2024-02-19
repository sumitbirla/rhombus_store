class Admin::Store::OrdersController < Admin::BaseController

  def index
    authorize Order.new
    q = params[:q]

    @orders = Order.order(sort_column + " " + sort_direction)
    @orders = @orders.where(status: params[:status]) unless params[:status].blank?
    @orders = @orders.where(batch_id: params[:batch_id]) unless params[:batch_id].blank?
    @orders = @orders.joins(:items).where("store_order_items.product_id = ?", params[:product_id]) unless params[:product_id].blank?
    @orders = @orders.where(domain_id: cookies[:domain_id]) if q.blank?
    @orders = @orders.where(sales_channel: params[:sales_channel]) unless params[:sales_channel].blank?

    unless q.blank?
      if (q.to_i == 0 || q.include?('-'))
        @orders = @orders.where("billing_name LIKE '%#{q}%' OR shipping_name LIKE '%#{q}%' OR external_order_id = '#{q}' OR external_order_name LIKE '%#{q}%'")
      else
        @orders = @orders.where(id: q)
      end
    end

    respond_to do |format|
      format.html { @orders = @orders.includes(:user, :affiliate, :shipments).paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Order.to_csv(@orders, skip_cols: ['cart_key', 'paypal_token']) }
    end
  end

  def new
    unless params[:user_id].nil? && params[:affiliate_id].nil?
      old_order = Order.where(user_id: params[:user_id], affiliate_id: params[:affiliate_id]).last
      unless old_order.nil?
        @order = old_order.dup

        @order.assign_attributes(
            submitted: DateTime.now,
            status: 'submitted',
            external_order_id: nil,
            cc_type: nil,
            cc_number: nil,
            cc_code: nil,
            cc_expiration_month: nil,
            cc_expiration_year: nil,
            paypal_token: nil,
            subtotal: 0.0,
            total: 0.0,
            tax_rate: 0.0,
            tax_amount: 0.0
        )

        @order.items
      end
    end

    if @order.nil?
      @order = Order.new(
          user_id: params[:user_id],
          affiliate_id: params[:affiliate_id],
          status: :submitted,
          domain_id: cookies[:domain_id],
          submitted: DateTime.now,
      )

      ouser = User.find_by(id: params[:user_id])
      @order.assign_attributes(contact_phone: ouser.phone, notify_email: ouser.email) unless ouser.nil?
    end
    5.times { @order.items.build }

    authorize @order
    render 'edit'
  end

  def create
    @order = authorize Order.new(order_params)
    @order.cart_key = SecureRandom.hex

    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @order.items.length + 5
      count.times { @order.items.build }
      return render 'edit'
    end

    if @order.save
      redirect_to action: 'index', notice: 'Order was successfully created.'
    else
      5.times { @order.items.build }
      render 'edit'
    end
  end

  def show
    @order = Order.includes(items: {product: [:pictures, :brand]}, history: :user).find(params[:id])
    authorize @order
  end

  def edit
    @order = authorize Order.find(params[:id])
    2.times { @order.items.build }
    2.times { @order.extra_properties.build }
  end

  def update
    @order = authorize Order.find(params[:id])
    item_count = @order.items.length

    @order.assign_attributes(order_params)

    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - item_count + 5
      count.times { @order.items.build }
      return render 'edit'
    end

    if @order.save(validate: false)
      @order.update_price_list if (@order.po && @order.affiliate_id && params[:update_price_list] == "1")
      redirect_to action: 'show', id: @order.id, notice: 'Order was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @order = authorize Order.find(params[:id])
    @order.destroy
    redirect_to action: 'index', notice: 'Order has been deleted.'
  end


  def resend_email
    @order = Order.find(params[:id])

    begin
      OrderMailer.order_submitted(@order.id, session[:user_id]).deliver_now
      flash[:notice] = "Order confirmation has been emailed to #{@order.notify_email}"
    rescue => e
      flash[:notice] = e.message
    end

    redirect_back(fallback_location: admin_root_path)
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
    authorize @order, :show?
  end


  def update_status
    authorize Order.new, :update?

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
    redirect_back(fallback_location: admin_root_path)
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

    output_file = "/tmp/#{SecureRandom.hex(6)}.pdf"
    ret = system("wkhtmltopdf -q -s Letter #{urls} #{output_file}")

    unless File.exist?(output_file)
      flash[:error] = "Unable to generate PDF [Debug: #{$?}]"
      return redirect_back(fallback_location: admin_root_path)
    end

    if params[:printer_id].blank?
      send_file output_file
    else
      printer = Printer.find(params[:printer_id])
      job = printer.print_file(output_file)
      flash[:info] = "Print job submitted to '#{printer.name} [#{printer.location}]'. CUPS JobID: #{job.id}"
      redirect_back(fallback_location: admin_root_path)
    end
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

    redirect_back(fallback_location: admin_root_path)
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

    redirect_back(fallback_location: admin_root_path)
  end

  def create_shipment
    orders = Order.includes(:shipments).where(id: params[:order_id])
    count = 0

    orders.each do |o|
      if o.shipments.length == 0
        shipment = o.create_shipment(session[:user_id])
        count += 1 if shipment
      end
    end

    flash[:info] = "#{count} new shipments created"
    redirect_back(fallback_location: admin_root_path)
  end

  def batch_ship
    orders = Order.includes(:shipments).where(id: params[:order_id])
    shipment_ids = []

    orders.each do |o|
      if o.shipments.length == 0
        shipment = o.create_shipment(session[:user_id])
        shipment_ids << shipment.id
      else
        shipment_ids << o.shipments[0].id
      end
    end

    redirect_to admin_store_shipments_batch_path(shipment_id: shipment_ids)
  end

  def clone
    order = Order.find(params[:id])
    new_order = order.dup

    new_order.assign_attributes({
                                    submitted: DateTime.now,
                                    status: :submitted,
                                    ship_earliest: Date.today,
                                    payment_due: nil,
                                    cc_type: nil,
                                    cc_number: nil,
                                    cc_code: nil,
                                    cc_expiration_month: nil,
                                    cc_expiration_year: nil,
                                    paypal_token: nil,
                                    cart_key: ''
                                })
    new_order.save(validate: false)

    order.items.each { |x| new_order.items << x.dup }
    redirect_to action: 'edit', id: new_order.id
  end


  private

  def order_params
    params.require(:order).permit!
  end

  def sort_column
    params[:sort] || "store_orders.id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

end

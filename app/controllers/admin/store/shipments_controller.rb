require 'countries'
require 'base64'
require 'socket'
require 'easypost'
require 'net/http'
require 'net/scp'
require 'uri'


class Admin::Store::ShipmentsController < Admin::BaseController
  skip_before_action :verify_authenticity_token, only: :label_print, raise: false

  def index
    authorize Shipment.new

    q = params[:q]
    s = Shipment.includes(:order, :items, :fulfiller, :inventory_transaction, [items: :order_item]).order(sort_column + " " + sort_direction)
    s = s.where("store_orders.user_id = ?", params[:user_id]) unless params[:user_id].blank?
    s = s.where("store_orders.affiliate_id = ?", params[:affiliate_id]) unless params[:affiliate_id].blank?
    s = s.where(carrier: params[:carrier]) unless params[:carrier].blank?
    s = s.where(ship_date: params[:ship_date]) unless params[:ship_date].blank?
    s = s.where(status: params[:status]) unless params[:status].blank?
    s = s.where(manifest_id: params[:manifest_id]) unless params[:manifest_id].blank?

    unless q.blank?
      # if an exact shipment was scanned in, redirect to the shipment#show page
      if q.match(/\d{5}-\d{1,2}/)
        order_id, sequence = q.split("-")
        shp = Shipment.find_by(order_id: order_id, sequence: sequence)
        return redirect_to admin_store_shipment_path(shp) unless shp.nil?
      end

      s = s.where("recipient_name LIKE '%#{q}%' OR recipient_company LIKE '%#{q}%' OR recipient_city LIKE '%#{q}%'")
    end


    if current_user.admin?
      s = s.where(fulfilled_by_id: params[:fulfilled_by_id]) unless params[:fulfilled_by_id].blank?
    else
      s = s.where(fulfilled_by_id: current_user.affiliate_id)
    end

    respond_to do |format|
      format.html { @shipments = s.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Shipment.to_csv(s, skip_cols: ['label_data']) }
    end
  end

  def new
    # check if order id was passed in?
    return redirect_to action: 'choose_order' if params[:order_id].nil?

    @order = Order.find(params[:order_id])

    if @order.nil?
      flash[:notice] = "Order #{params[:order_id]} was not found."
      return redirect_to action: 'choose_order'
    end

    begin
      @shipment = authorize @order.create_fulfillment(params[:fulfiller_id], session[:user_id], false)
    rescue => e
      flash[:error] = e.message
      return redirect_back(fallback_location: admin_root_path)
    end

    @shipment.invoice_amount = @order.total if @shipment.sequence == 1
    render 'edit'
  end

  def create
    @shipment = authorize Shipment.new(shipment_params)

    if @shipment.save
      # create order history item
      OrderHistory.create order_id: @shipment.order_id, user_id: current_user.id, event_type: :shipment_created,
                          system_name: 'Rhombus', identifier: @shipment.id, comment: "shipment created: #{@shipment}"

      flash[:notice] = "Shipment #{@shipment.order_id}-#{@shipment.sequence} was successfully created."
      redirect_to action: 'show', id: @shipment.id
    else
      render 'edit'
    end
  end

  def show
    @shipment = authorize Shipment.includes(items: {order_item: {product: :brand}}).find(params[:id])
  end

  def edit
    @shipment = authorize Shipment.includes(:items, [items: :order_item]).find(params[:id])

    # add any items that were added to Order later and not currently present in Shipment
    @shipment.order.items.each do |oi|
      unless @shipment.items.any? { |x| x.order_item_id == oi.id }
        if oi.product.fulfiller_id == @shipment.fulfilled_by_id
          @shipment.items.build(order_item_id: oi.id, quantity: 0)
        end
      end
    end
  end

  def update
    @shipment = authorize Shipment.find(params[:id])
    @shipment.fulfilled_by_id = current_user.id

    if @shipment.update(shipment_params)
      flash[:notice] = "Shipment #{@shipment.order_id}-#{@shipment.sequence} was updated."
      redirect_to action: 'show', id: @shipment.id
    else
      render 'edit'
    end
  end

  def destroy
    @shipment = authorize Shipment.find(params[:id])
    @shipment.destroy
    redirect_back(fallback_location: admin_root_path)
  end

  def packing_slip
    @shipment = Shipment.includes(:items, [items: :order_item]).find(params[:id])
    render 'packing_slip', layout: false
  end

  def invoice
    @shipment = Shipment.find(params[:id])
    render 'invoice', layout: false
  end

  def email_invoice
    @shipment = Shipment.find(params[:id])
    SendInvoiceJob.perform_later(@shipment.id, session[:user_id])

    flash[:success] = "Invoice was emailed to #{@shipment.order.notify_email}"
    redirect_back(fallback_location: admin_root_path)
  end

  def choose_order
  end

  def label_image
    shipment = Shipment.find(params[:id])
    send_data shipment.label_data, type: shipment.label_format
  end

  def label
    return render text: :ok

    # used background processing for printing to thermal printer as it can take a few seconds
    if ['epl2', 'zpl'].include?(params[:format])
      ShippingLabelJob.perform_later(session[:user_id], params[:id], params[:format])
      flash[:info] = "Shipping label dispatched to printer"
      return redirect_back(fallback_location: admin_root_path)
    end

    # requested a PNG probably
    shipment = Shipment.find(params[:id])
    courier_data = JSON.parse(shipment.courier_data)

    begin
      EasyPost.api_key = shipment.easy_post_api_key
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.label({'file_format' => params[:format]})

      # download label
      label_url = response[:postage_label]["label_#{params[:format]}_url"]
      label_data = Net::HTTP.get(URI.parse(label_url))

    rescue => e
      flash[:error] = "Error downloading shipping label: " + e.message
      return redirect_back(fallback_location: admin_root_path)
    end

    send_data label_data, filename: shipment.to_s + "." + params[:format]
  end

  def void_label
    shipment = Shipment.find(params[:id])
    EasyPost.api_key = shipment.easy_post_api_key
    courier_data = JSON.parse(shipment.courier_data)

    begin
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.refund
      flash[:info] = "Refund status: #{response[:refund_status]} - / - Tracking: #{response[:tracking_code]} - / - Confirmation: #{response[:confirmation_number] || "n/a"}"
      shipment.update_attribute(:status, 'void') if ['submitted', 'refunded'].include?(response[:refund_status])
    rescue => e
      flash[:error] = e.message
    end

    redirect_back(fallback_location: admin_root_path)
  end

  def product_labels_pending
    @shipments = Shipment.where(status: :ready_to_ship)

    sql = <<-EOF
      select si.shipment_id, si.id as shipment_item_id, sheet.name as label, oi.item_number, p.name, p.option_title, 
            sum(si.quantity) as quantity, uploaded_file, upload_file_preview, rendered_file
      from store_shipment_items si
      join store_order_items oi on oi.id = si.order_item_id
      join store_products p on p.id = oi.product_id
      join store_label_sheets sheet on sheet.id = p.label_sheet_id
      where shipment_id in (#{@shipments.map(&:id).join(",")})
      and si.quantity > 0
      group by oi.item_number, uploaded_file
      order by sheet.name, oi.item_number;
    EOF

    @items = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @items << row.with_indifferent_access }

    render 'product_labels'
  end

  def product_labels
    if params[:shipment_id].blank?
      flash[:error] = "No shipments selected.  Please check at least one."
      return redirect_back(fallback_location: admin_root_path)
    end

    @shipments = Shipment.where(id: params[:shipment_id])

    sql = <<-EOF
      select si.shipment_id, si.id as shipment_item_id, sheet.name as label, oi.item_number, p.name, p.option_title, 
              sum(si.quantity) as quantity, uploaded_file, upload_file_preview, rendered_file
      from store_shipment_items si
      join store_order_items oi on oi.id = si.order_item_id
      join store_products p on p.id = oi.product_id
      join store_label_sheets sheet on sheet.id = p.label_sheet_id
      where shipment_id in (#{params[:shipment_id].join(",")})
      and si.quantity > 0
      group by oi.item_number, uploaded_file
      order by sheet.name, oi.item_number;
    EOF

    @items = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @items << row.with_indifferent_access }
  end

  # Print one size of labels
  def label_print

    # First find the printer
    p = Printer.find_by(id: params[:printer_id])
    if p.nil?
      flash[:error] = "Printer not found"
      return redirect_back(fallback_location: admin_root_path)
    end

    # See which label size this job is for (poor English here)
    label_prefix = Setting.get(Rails.configuration.domain_id, :kiaro, "Label Prefix")
    label = params[:label].split(" ", 2)[1] + ".alf"
    label_count = 0
    str = ""
    logs = []

    # LOOP through the items selected
    params[:print_items].each do |h|
      # puts h.inspect
      next if h['quantity'] == "0"
      next if h['personalized'] == 'true' && h['rendered_file'].blank?

      qty = h['quantity'].to_i
      label_count += qty

      ### QUICKCOMMAND LABEL SPECS #########
      str << "LABELNAME=#{label}\r\n"

      if h['personalized'] == 'true'
        img = h['rendered_file'].split('/').last
        str << "FIELD 001=#{label_prefix}\\personalized_labels\\#{img}\r\n"
      else
        prod = Product.find_by(item_number: h['item_number'])

        # handle nothing to print
        if prod.nil? || prod.label_file.blank?
          flash[:error] = "Label is not configured for item [#{h['item_number']}].  Cannot print."
          return redirect_back(fallback_location: admin_root_path)
        end

        str << "FIELD 001=#{label_prefix}#{prod.label_file.tr('/', '\\')}\r\n"
      end

      str << "LABELQUANTITY=#{qty}\r\n"
      str << "PRINTER=#{p.url}\r\n\r\n"
      ######################################

      logs << Log.new(timestamp: DateTime.now,
                      loggable_type: 'Printer',
                      loggable_id: p.id,
                      event: :label_printed,
                      data1: h['item_number'],
                      data2: qty,
                      data3: p.name,
                      ip_address: request.remote_ip,
                      user_id: session[:user_id])
    end

    # handle nothing to print
    if label_count == 0
      flash[:error] = "No labels specified for printing."
      return redirect_back(fallback_location: admin_root_path)
    end

    # puts str
    # flash[:error] = "Testing short circuit."
    # return redirect_back(fallback_location: admin_root_path)

    # SCP file over to server
    tmp_file = "/tmp/" + Time.now.strftime("%Y-%m-%d-%H%M%S") + ".acf"
    File.write(tmp_file, str)

    # example  scp://user:pass@server1.mydomain.com:/home/kiaro/monitor/
    uri = URI(Setting.get(Rails.configuration.domain_id, :kiaro, "Print Job URI"))

    begin
      Net::SCP.upload!(uri.host, uri.user, tmp_file, uri.path, :ssh => {:password => uri.password, :port => uri.port || 22})
      flash[:success] = "#{label_count} labels submitted for printing"
      logs.each(&:save)
      Log.create(timestamp: DateTime.now, loggable_type: 'Printer', loggable_id: p.id, event: :job_submitted,
                 data1: label, data2: label_count, ip_address: request.remote_ip, user_id: session[:user_id])
    rescue => e
      flash[:error] = e.message
    end

    File.delete(tmp_file)
    redirect_back(fallback_location: admin_root_path)
  end

  def packing_slip_batch
    if params[:shipment_id].blank?
      flash[:error] = "No shipments selected. Please check at least one."
      return redirect_back(fallback_location: admin_root_path)
    end

    urls = ''
    token = Cache.setting(Rails.configuration.domain_id, :system, 'Security Token')
    website_url = Cache.setting(Rails.configuration.domain_id, :system, 'Website URL')

    Shipment.where(id: params[:shipment_id]).each do |s|
      digest = Digest::MD5.hexdigest(s.id.to_s + token)
      urls += " " + website_url + packing_slip_admin_store_shipment_path(s, digest: digest)

      OrderHistory.create(order_id: s.order_id, user_id: session[:user_id], event_type: :packing_slip_print, system_name: 'Rhombus', comment: "Packing slip printed")
    end

    output_file = "/tmp/#{SecureRandom.hex(6)}.pdf"
    Rails.logger.debug("wkhtmltopdf -q -s Letter --dpi 300 #{urls} #{output_file}")
    ret = system("wkhtmltopdf -q -s Letter --dpi 300 #{urls} #{output_file}")

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

  def shipping_label_batch
    if params[:printer_id].blank?
      file_format = 'pdf'
    else
      p = Printer.find(params[:printer_id])
      file_format = p.preferred_format
      mime_type = (file_format == 'pdf' ? 'application/pdf' : 'text/plain')
    end

    count = 0

    begin
      Shipment.where(id: params[:shipment_id]).each do |s|
        courier_data = JSON.parse(s.courier_data)

        EasyPost.api_key = s.easy_post_api_key

        ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
        response = ep_shipment.label({'file_format' => file_format})

        # download label
        label_url = response[:postage_label]["label_#{file_format}_url"]
        label_data = Net::HTTP.get(URI.parse(label_url))

        if params[:printer_id].blank?
          return send_data label_data, filename: s.to_s + "." + file_format
        else
          p.print_data(label_data, mime_type)
          count += 1
        end
      end
    rescue => e
      flash[:error] = e.message
      return redirect_back(fallback_location: admin_root_path)
    end

    flash[:info] = "#{count} label(s) sent to #{p.name} [#{p.location}]"
    redirect_back(fallback_location: admin_root_path)
  end

  def update_status
    authorize Shipment.new, :update?
    shipments = Shipment.where(id: params[:shipment_id]).where.not(status: params[:status])
    shipments.each do |s|
      s.update_attribute(:status, params[:status])
      if s.status == 'shipped' && s.ship_date.nil?
        s.update_attribute(:ship_date, Date.today)
      end
    end

    flash[:info] = "Status of #{shipments.length} shipment(s) updated to '#{params[:status]}'"
    redirect_back(fallback_location: admin_root_path)
  end

  def email_confirmation
    shipment = Shipment.find(params[:id])

    begin
      OrderMailer.order_shipped(shipment.id, session[:user_id]).deliver_now
      flash[:info] = "Shipment email sent to '#{shipment.order.notify_email}'"
    rescue => e
      flash[:info] = e.message
    end

    redirect_back(fallback_location: admin_root_path)
  end

  def batch
    if params[:shipment_id].blank?
      flash[:error] = "No shipments selected. Please check at least one."
      return redirect_back(fallback_location: admin_root_path)
    end

    @shipments = Shipment.where(id: params[:shipment_id])
    @batch = Shipment.new(ship_date: Date.today)

    # Check to make sure that the batch contains shipments with identical contents
    if @shipments.collect(&:items_hash).uniq.length > 1
      flash.now[:warning] = "Selected batch contains more that one configuration of shipment."
      #return redirect_back(fallback_location: admin_root_path)
    end

    # try to autopopulate fields
    # if identical shipment was recentely shipped with same contents, set box size and weight
    s = @shipments[0].similar_shipment

    unless s.nil?
      @batch = s.dup
      @batch.ship_date = Date.today
    end
  end

  def auto_batch
    @shipments = Shipment.where(status: :pending, items_hash: params[:items_hash])
    @batch = Shipment.new(ship_date: Date.today, items_hash: params[:items_hash])

    # try to autopopulate fields
    # if identical shipment was recentely shipped with same contents, set box size and weight
    s = @shipments[0].similar_shipment

    unless s.nil?
      @batch = s.dup
      @batch.ship_date = Date.today
    end

    render 'batch'
  end

  def scan
    @shipment = Shipment.includes(:items, [items: :product], [items: :affiliate]).find(params[:id])
  end

  def verify_scan
    @shipment = Shipment.includes(:items, [items: :product], [items: :affiliate]).find(params[:id])
    scan_list = params["upc_list"].split("\n").map { |x| x.chomp! }

    @scans = {}
    scan_list.each do |scan|
      @scans[scan] = 0 if @scans[scan].nil?
      @scans[scan] += 1
    end

    render 'scan'
  end

  def create_inventory_transaction
    @shipment = Shipment.includes(:items).find(params[:id])

    begin
      tran = @shipment.new_inventory_transaction
      tran.external_id = @shipment.uuid
      tran.responsible_party = current_user.name
      tran.save!
    rescue => e
      flash[:error] = e.message
    end

    redirect_back(fallback_location: admin_root_path)
  end


  private

  def shipment_params
    params.require(:shipment).permit!
  end

  def sort_column
    params[:sort] || "store_shipments.id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end

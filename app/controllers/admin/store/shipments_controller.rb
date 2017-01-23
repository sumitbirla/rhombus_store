require 'countries'
require 'base64'
require 'socket'
require 'easypost'
require 'net/http'
require 'net/scp'
require 'uri'


class Admin::Store::ShipmentsController < Admin::BaseController
  
  skip_before_filter  :verify_authenticity_token, only: :label_print

  def index
    q = params[:q]
    s = Shipment.includes(:order, :items, :inventory_transaction, [items: :order_item]).order('store_shipments.created_at DESC')
    s = s.where("recipient_name LIKE '%#{q}%' OR recipient_company LIKE '%#{q}%' OR recipient_city LIKE '%#{q}%'")
    s = s.where("store_orders.user_id = ?", params[:user_id]) unless params[:user_id].blank?
    s = s.where("store_orders.affiliate_id = ?", params[:affiliate_id]) unless params[:affiliate_id].blank?
    s = s.where(carrier: params[:carrier]) unless params[:carrier].blank?
    s = s.where(ship_date: params[:ship_date]) unless params[:ship_date].blank?
    s = s.where(status: params[:status]) unless params[:status].blank?
    s = s.where(manifest_id: params[:manifest_id]) unless params[:manifest_id].blank?
    
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

    @shipment = @order.create_shipment(session[:user_id], false)
    @shipment.invoice_amount = @order.total if @shipment.sequence == 1
                    
    render 'edit'
  end


  def create
    @shipment = Shipment.new(shipment_params)
    @shipment.fulfilled_by_id = current_user.id
    
    puts ">>>>>>>>>>>  #{@shipment.skip_inventory}"

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
    @shipment = Shipment.includes(:items, [items: :product], [items: :affiliate]).find(params[:id])
  end


  def packing_slip
    @shipment = Shipment.includes(:items, [items: :product], [items: :affiliate], [items: :order_item]).find(params[:id])
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
    redirect_to :back
  end
  
  def create_payment
    @shipment = Shipment.find(params[:id])
    
    if @shipment.post_invoice                   
      OrderHistory.create(order_id: @shipment.order.id, user_id: session[:user_id], 
                        event_type: :invoice, system_name: 'Rhombus', identifier: @shipment.to_s,
                        comment: "Invoiced $#{@shipment.invoice_amount}" )
      flash[:success] = 'Invoice posted'
    else
      flash[:error] = 'Invoice was not posted'
    end
    
    redirect_to :back                    
  end


  def edit
    @shipment = Shipment.includes(:items, [items: :product], [items: :affiliate], [items: :order_item]).find(params[:id])
  end


  def update
    @shipment = Shipment.find(params[:id])
    @shipment.fulfilled_by_id = current_user.id

    if @shipment.update(shipment_params)
      flash[:notice] = "Shipment #{@shipment.order_id}-#{@shipment.sequence} was updated."
      redirect_to action: 'show', id: @shipment.id
    else
      render 'edit'
    end

  end


  def destroy
    Shipment.find(params[:id]).destroy
    redirect_to :back
  end


  def choose_order
  end
  
  def label_image
    shipment = Shipment.find(params[:id])
    send_data shipment.label_data, type: shipment.label_format
  end


  def label
    # used background processing for printing to thermal printer as it can take a few seconds
    if ['epl2','zpl'].include?(params[:format])
      ShippingLabelJob.perform_later(session[:user_id], params[:id], params[:format])
      flash[:info] = "Shipping label dispatched to printer"
      return redirect_to :back
    end
    
    # requested a PNG probably
    shipment = Shipment.find(params[:id])
    courier_data = JSON.parse(shipment.courier_data)
    
    begin
      EasyPost.api_key = Cache.setting(shipment.order.domain_id, 'Shipping', 'EasyPost API Key')
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.label({'file_format' => params[:format]})
      
      # download label
      label_url = response[:postage_label]["label_#{params[:format]}_url"]
      label_data = Net::HTTP.get(URI.parse(label_url))
      
    rescue => e
      flash[:error] = "Error downloading shipping label: " + e.message
      return redirect_to :back
    end
    
    send_data label_data, filename: shipment.to_s + "." + params[:format]
  end


  def void_label
    shipment = Shipment.find(params[:id])
    EasyPost.api_key = Cache.setting(shipment.order.domain_id, 'Shipping', 'EasyPost API Key')
    courier_data = JSON.parse(shipment.courier_data)
    
    begin
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.refund
      flash[:info] = "Refund status: #{response[:refund_status]} - / - Tracking: #{response[:tracking_code]} - / - Confirmation: #{response[:confirmation_number] || "n/a"}"
      shipment.update_attribute(:status, 'void') if response[:refund_status] == 'submitted'
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to :back
  end
  
  def product_labels_pending
    @shipments = Shipment.where(status: :pending)
    
    sql = <<-EOF
      select sheet.name as label, p.sku, a.code, item.variation, p.name, p.option_title, sum(quantity) as quantity
      from store_shipment_items item
      join store_shipments shp on shp.id = item.shipment_id
      join store_products p on p.id = item.product_id
      left join core_affiliates a on a.id = item.affiliate_id
      join store_label_sheets sheet on sheet.id = p.label_sheet_id
      where shp.id in (#{@shipments.map(&:id).join(",")})
      and item.quantity > 0
      group by p.sku, a.code, item.variation
      order by p.label_sheet_id, p.id;
    EOF
    
    @items = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @items << row.with_indifferent_access }
    
    render 'product_labels'
  end

  def product_labels
    @shipments = Shipment.where(status: params[:shipment_id])
    
    sql = <<-EOF
      select sheet.name as label, p.sku, a.code, item.variation, p.name, p.option_title, sum(quantity) as quantity
      from store_shipment_items item
      join store_shipments shp on shp.id = item.shipment_id
      join store_products p on p.id = item.product_id
      left join core_affiliates a on a.id = item.affiliate_id
      join store_label_sheets sheet on sheet.id = p.label_sheet_id
      where shp.id in (#{params[:shipment_id].join(",")})
      group by p.sku, a.code, item.variation
      order by p.label_sheet_id, p.id;
    EOF
    
    @items = []
    ActiveRecord::Base.connection.execute(sql).each(as: :hash) { |row| @items << row.with_indifferent_access }
  end
  
  def label_print
    label_prefix = Setting.get(:kiaro, "Label Prefix")
    label = params[:label].split(" ", 2)[1] + ".alf"
    label_count = 0
    str = ""
    
    params.each do |k,v|
      if k.start_with?("item-")
        item, sku, breed, variant = k.split("-")
        qty = v.to_i
        label_count += qty
        
        if qty > 0
          str << "LABELNAME=#{label}\r\n"
          str << "FIELD 001=#{label_prefix}\\#{breed}\\#{sku}-#{breed}-#{variant}.pdf\r\n"
          str << "LABELQUANTITY=#{qty}\r\n"
          str << "PRINTER=QuickLabel Kiaro;Kiaro!\r\n\r\n"
        end
      end
    end
    
    # handle nothing to print
    if label_count == 0
      flash[:error] = "No labels specified for printing."
      return redirect_to :back
    end
    
    puts str
    # SCP file over to server
    tmp_file = "/tmp/" + Time.now.strftime("%Y-%m-%d-%H%M%S") + ".acf"
    File.write(tmp_file, str)
    
    host = Setting.get(:kiaro, "SCP Host")
    port = Setting.get(:kiaro, "SCP Port")
    user = Setting.get(:kiaro, "SCP Username")
    pass = Setting.get(:kiaro, "SCP Password")
    dir = Setting.get(:kiaro, "SCP Directory")
    
    begin
      Net::SCP.upload!(host, user, tmp_file, dir, :ssh => { :password => pass, :port => port })
      flash[:success] = "#{label_count} labels submitted for printing"
    rescue => e
      flash[:error] = e.message
    end
    
    File.delete(tmp_file)
    redirect_to :back
  end
  
  
  def packing_slip_batch
    urls = ''
    token = Cache.setting(Rails.configuration.domain_id, :system, 'Security Token')
    website_url = Cache.setting(Rails.configuration.domain_id, :system, 'Website URL')
    
    Shipment.where(id: params[:shipment_id]).each do |s|
      digest = Digest::MD5.hexdigest(s.id.to_s + token) 
      urls += " " + website_url + packing_slip_admin_store_shipment_path(s, digest: digest) 
      
      OrderHistory.create(order_id: s.order_id, 
                          user_id: session[:user_id], 
                          event_type: :packing_slip_print,
                          system_name: 'Rhombus',
                          comment: "Packing slip printed")
    end
    
    system "wkhtmltopdf -q #{urls} /tmp/packing_slips.pdf"
    send_file "/tmp/packing_slips.pdf"
  end
  
  def invoice_batch
    urls = ''
    token = Cache.setting('System', 'Security Token')
    website_url = Cache.setting('System', 'Website URL')
    
    Shipment.where(id: params[:shipment_id]).each do |s|
      digest = Digest::MD5.hexdigest(s.id.to_s + token) 
      urls += " " + website_url + invoice_admin_store_shipment_path(s, digest: digest) 
    end
    
    system "wkhtmltopdf -q #{urls} /tmp/receipts.pdf"
    send_file "/tmp/receipts.pdf"
  end
  
  
  def update_status
    shipments = Shipment.where(id: params[:shipment_id]).where.not(status: params[:status])
    shipments.each do |s|
      s.update_attribute(:status, params[:status])
      if s.status == 'shipped' && s.ship_date.nil?
        s.update_attribute(:ship_date, Date.today)
      end
    end
    
    flash[:info] = "Status of #{shipments.length} shipment(s) updated to '#{params[:status]}'"
    redirect_to :back
  end
  
  
  def email_confirmation    
    shipment = Shipment.find(params[:id])
    
    begin
      OrderMailer.order_shipped(shipment.id, session[:user_id]).deliver_now
      flash[:info] = "Shipment email sent to '#{shipment.order.notify_email}'"
    rescue => e
      flash[:info] = e.message
    end
    
    redirect_to :back
  end


  def batch
    @shipments = Shipment.where(id: params[:shipment_id])
    
    if @shipments.length == 0
      flash[:error] = "No shipments selected."
      return redirect_to :back
    end
    
    @batch = Shipment.new(ship_date: Date.today)
    
    # try to autopopulate fields
    shipments = Shipment.includes(:items)
                        .where(status: :shipped)
                        .order(ship_date: :desc)
                        .limit(10)
    
    shipments.each do |s|
      if s.same_content?(@shipments[0])
        @batch = s.dup
        @batch.ship_date = Date.today
        break
      end
    end
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
    @shipment = Shipment.includes(:items, [items: :product]).find(params[:id])
    
    begin
      tran = @shipment.new_inventory_transaction
      tran.shipment_id = @shipment.id
      tran.save!
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to :back
  end


  private

  def shipment_params
    params.require(:shipment).permit!
  end

end

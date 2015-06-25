require 'countries'
require 'base64'
require 'socket'
require 'easypost'
require 'net/http'
require 'uri'


class Admin::Store::ShipmentsController < Admin::BaseController

  def index
    q = params[:q]
    @shipments = Shipment.all.order('created_at DESC')
    @shipments = @shipments.where("recipient_name LIKE '%#{q}%' OR recipient_company LIKE '%#{q}%' OR recipient_city LIKE '%#{q}%'")
    @shipments = @shipments.where(status: params[:status]) unless params[:status].blank?
    
    respond_to do |format|
      format.html { @shipments = @shipments.page(params[:page]) }
      format.csv { send_data @shipments.to_csv }
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

    seq = 1
    max_seq = @order.shipments.maximum(:sequence)
    seq = max_seq + 1 unless max_seq.nil?

    @shipment = Shipment.new(order_id: @order.id,
                             sequence: seq,
                             recipient_company: @order.shipping_company,
                             recipient_name: @order.shipping_name,
                             recipient_street1: @order.shipping_street1,
                             recipient_street2: @order.shipping_street2,
                             recipient_city: @order.shipping_city,
                             recipient_state: @order.shipping_state,
                             recipient_zip: @order.shipping_zip,
                             recipient_country: @order.shipping_country,
                             package_weight: 1.0,
                             status: 'pending')

     loc_id = Cache.setting(@order.domain_id, :shipping, "Ship From Location ID")
     loc = Location.find(loc_id) if loc_id

     unless loc.nil?
       @shipment.assign_attributes(ship_from_company: loc.name,
                                   ship_from_street1: loc.street1,
                                   ship_from_street2: loc.street2,
                                   ship_from_city: loc.city,
                                   ship_from_state: loc.state,
                                   ship_from_zip: loc.zip,
                                   ship_from_country: loc.country,
                                   ship_from_email: loc.email,
                                   ship_from_phone: loc.phone)
    end 
    
    # prepopulate with items to ship
    @order.items.each do |item|
      @shipment.items.build(order_item_id: item.id, quantity: item.quantity)
    end
    
    # set invoice amount
    @shipment.invoice_amount = @order.total if seq == 1
                    
    render 'edit'
  end


  def create
    @shipment = Shipment.new(shipment_params)
    @shipment.fulfilled_by_id = current_user.id

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
    @shipment = Shipment.includes(:items, [items: :order_item]).find(params[:id])
  end


  def packing_slip
    @shipment = Shipment.find(params[:id])
    render 'packing_slip', layout: false
  end
  
  def invoice
    @shipment = Shipment.find(params[:id])                       
    render 'invoice', layout: false
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
    @shipment = Shipment.find(params[:id])
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
    @shipment = Shipment.find(params[:id])
    @shipment.destroy

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
      EasyPost.api_key = Cache.setting('Shipping', 'EasyPost API Key')
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
    EasyPost.api_key = Cache.setting('Shipping', 'EasyPost API Key')
    shipment = Shipment.find(params[:id])
    courier_data = JSON.parse(shipment.courier_data)
    
    begin
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.refund
      flash[:info] = "Refund status: #{response[:status]} - / - Tracking: #{response[:tracking_code]} - / - Confirmation: #{response[:confirmation_number] || "n/a"}"
      shipment.update_attribute(:status, 'void') if response[:status] == 'submitted'
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to :back
  end

  def product_labels
    @shipment_items = ShipmentItem.includes(:order_item, [order_item: :product]).where(shipment_id: params[:shipment_id])
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
  end

  def scan
    @shipment = Shipment.find(params[:id])
  end
  
  def verify_scan
    @shipment = Shipment.find(params[:id])
    scan_list = params["upc_list"].split("\n").map { |x| x.chomp! }
    
    @scans = {}
    scan_list.each do |scan|
      @scans[scan] = 0 if @scans[scan].nil?
      @scans[scan] += 1
    end
    
    render 'scan'
  end


  private

  def shipment_params
    params.require(:shipment).permit!
  end

end

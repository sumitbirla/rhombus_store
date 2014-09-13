require 'countries'
require 'base64'
require 'socket'
require 'easypost'
require 'net/http'
require 'uri'


class Admin::Store::ShipmentsController < Admin::BaseController

  def index
    @shipments = Shipment.all.order('created_at DESC').page(params[:page])
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

    last_shipment = Shipment.order("created_at DESC").take(1)[0]

    @shipment = Shipment.new order_id: @order.id,
                             sequence: seq,
                             recipient_company: @order.shipping_company,
                             recipient_name: @order.shipping_name,
                             recipient_street1: @order.shipping_street1,
                             recipient_street2: @order.shipping_street2,
                             recipient_city: @order.shipping_city,
                             recipient_state: @order.shipping_state,
                             recipient_zip: @order.shipping_zip,
                             recipient_country: @order.shipping_country,
                             status: 'pending'


    # if this is the first shipment for this order, auto-create the shipment in database with all items included.do
    if seq == 1 && last_shipment

      @shipment.assign_attributes ship_from_company: last_shipment.ship_from_company,
                                  ship_from_street1: last_shipment.ship_from_street1,
                                  ship_from_street2: last_shipment.ship_from_street2,
                                  ship_from_city: last_shipment.ship_from_city,
                                  ship_from_state: last_shipment.ship_from_state,
                                  ship_from_zip: last_shipment.ship_from_zip,
                                  ship_from_country: last_shipment.ship_from_country

      if @shipment.save
        @order.items.each do |item|
          @shipment.items << ShipmentItem.new(shipment_id: @shipment.id, order_item_id: item.id, quantity: item.quantity)
        end

        OrderHistory.create order_id: @shipment.order_id, user_id: current_user.id, event_type: :shipment_created,
                          system_name: 'Rhombus', identifier: @shipment.id, comment: "shipment created: #{@shipment}"

        flash[:info] = "New shipment created."
        return redirect_to admin_store_shipment_path(@shipment)
      end

      flash[:info] = "Shipment could not be created"
      return redirect_to :back
    else

      @shipment_items = []
      @order.items.each do |item|
        @shipment_items << ShipmentItem.new(order_item_id: item.id)
      end

    end

    render 'edit'
  end


  def create

    @shipment = Shipment.new(shipment_params)
    @shipment.fulfilled_by_id = current_user.id

    # check if any items specified
    unless params.any? { |k,v| k.include?('qty-') && !v.blank? }

      flash[:error] = "Please pick at least one item to ship."

      @shipment_items = []
      @shipment.order.items.each do |item|
        @shipment_items << ShipmentItem.new(order_item_id: item.id)
      end

      return render 'edit'
    end

    if @shipment.save

      params.each do |key, qty|
        if key.include?('qty-') && !qty.blank? && qty != '0'
          ShipmentItem.create(shipment_id: @shipment.id, order_item_id: key[4..-1], quantity: qty)
        end
      end

      # create order history item
      OrderHistory.create order_id: @shipment.order_id, user_id: current_user.id, event_type: :shipment_created,
                          system_name: 'Rhombus', identifier: @shipment.id, comment: "shipment created: #{@shipment}"

      flash[:notice] = "Shipment #{@shipment.order_id}-#{@shipment.sequence} was successfully created."
      redirect_to action: 'show', id: @shipment.id
    else
      @shipment_items = []
      @order = Order.find(@shipment.order_id)
      @order.items.each do |item|
        @shipment_items << ShipmentItem.new(order_item_id: item.id)
      end
      render 'edit'
    end
  end

  def show
    @shipment = Shipment.find(params[:id])
  end


  def packing_slip
    @shipment = Shipment.find(params[:id])
    render 'packing_slip', layout: false
  end


  def edit
    @shipment = Shipment.find(params[:id])
    @shipment_items = ShipmentItem.where(shipment_id: params[:id])
  end


  def update
    @shipment = Shipment.find(params[:id])
    @shipment.fulfilled_by_id = current_user.id

    if @shipment.update(shipment_params)

      params.each do |key, qty|
        next if !key.include?('qty-')

        order_item_id =  key[4..-1].to_i
        shipment_item = @shipment.items.find { |si| si.order_item_id == order_item_id }

        if shipment_item.nil?
          ShipmentItem.create(shipment_id: @shipment.id, order_item_id: order_item_id, quantity: qty)
        else
          shipment_item.update_attribute(:quantity, qty)
        end

      end

      flash[:notice] = "Shipment #{@shipment.order_id}-#{@shipment.sequence} was updated."
      redirect_to action: 'show', id: @shipment.id
    else
      @shipment_items = ShipmentItem.where(shipment_id: params[:id])
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


  def label
    shipment = Shipment.find(params[:id])
    courier_data = JSON.parse(shipment.courier_data)
    
    begin
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.label({'file_format' => params[:format]})
      
      # download label
      label_url = response[:postage_label]["label_#{params[:format]}_url"]
      label_data = Net::HTTP.get(URI.parse(label_url))
      
      # send to thermal printer
      if ['epl2','zpl'].include?(params[:format])
        
        ip_addr = Cache.setting('Shipping', 'Thermal Printer IP')
        s = TCPSocket.new(ip_addr, 9100)
        s.send label_data, 0
        s.close
        flash[:info] = "Shipping label sent to #{ip_addr}."
        
        return redirect_to :back
      end
      
    rescue => e
      flash[:error] = "Error downloading shipping label: " + e.message
      return redirect_to :back
    end
    
    send_data label_data, filename: shipment.to_s + "." + params[:format]
  end


  def void_label
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
    @shipment = Shipment.find(params[:id])
  end


  private

  def shipment_params
    params.require(:shipment).permit(:order_id, :sequence, :status, :recipient_company, :recipient_name, :recipient_street1,
                 :recipient_street2, :recipient_city, :recipient_state, :recipient_zip, :recipient_country,
                 :ship_from_company, :ship_from_street1,
                 :ship_from_street2, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country,
                 :status, :ship_method, :tracking_number, :ship_date, :package_weight, :package_length, :package_width,
                 :package_height, :ship_cost, :notes, :packaging_type, :drop_off_type, :delivery_confirmation, :signature_confirmation)
  end

end

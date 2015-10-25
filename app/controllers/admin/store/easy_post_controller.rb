require 'easypost'

class Admin::Store::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
		@shipment.packaging_type = 'YOUR PACKAGING' if @shipment.packaging_type.blank?
    @shipment.ship_date = Date.today
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
    
    return render 'index' unless @shipment.valid?
		
    begin
      @response = create_ep_shipment(@shipment)
    rescue => e
      flash[:error] = e.message
    end

    render 'index'
  end
  
  # Purchases shipping for given shipment
  def buy
    @shipment = Shipment.find(params[:shipment_id])
    EasyPost.api_key = Cache.setting(@shipment.order.domain_id, :shipping, 'EasyPost API Key')
    
    begin
      ep_shipment = EasyPost::Shipment.retrieve(params[:ep_shipment_id])
      response = ep_shipment.buy(:rate => {:id => params[:rate_id]})
    rescue => e
      flash[:error] = e.message
      return redirect_to :back
    end
    
    @shipment.copy_easy_post(response)
    @shipment.status = 'shipped'
    @shipment.fulfilled_by_id = session[:user_id]
    @shipment.save!
  
    OrderHistory.create order_id: @shipment.order_id,
                              user_id: current_user.id,
                              event_type: 'package_shipped',
                              amount: @shipment.ship_cost,
                              system_name: response[:selected_rate][:carrier],
                              identifier: @shipment.tracking_number,
                              comment:  response[:selected_rate][:service]
    
    # Amazon orders need to be notified about shipment
    if @shipment.order.sales_channel == "Amazon.com"
      AmazonFulfillmentJob.perform_later(@shipment.id)
    else
      @shipment.post_invoice
    end
    
    # auto print label if specified in settings
    if Cache.setting(@shipment.order.domain_id, :shipping, "Auto Print EPL2") == "true"
      ShippingLabelJob.perform_later(session[:user_id], @shipment.id, "epl2")
      flash[:success] = "Shipping label sent to printer"
    end
    
    # email customer with tracking info if specified in settings
    if Cache.setting(@shipment.order.domain_id, :shipping, "Auto Email Tracking") == "true"
      unless @shipment.order.sales_channel == "Amazon.com"
        OrderMailer.order_shipped(@shipment.id, session[:user_id]).deliver_later
        flash[:info] = "Shipment confirmation sent to #{@shipment.order.notify_email}"
      end
    end
    
    # update inventory
    UpdateInventoryJob.perform_later(shipment_id: @shipment.id)
    
    redirect_to admin_store_shipment_path(@shipment)
  end
  
  # Creates an EasyPost shipment object which contains rates
  def batch
    shp = Shipment.new(shipment_params)
    
    job_params = {
      shipment_ids: params[:shipment_ids],
      carrier: shp.carrier,
      service: shp.ship_method,
      packaging: shp.packaging_type,
      length: shp.package_length.to_f,
      width: shp.package_width.to_f,
      height: shp.package_height.to_f,
      weight: shp.package_weight.to_f,
      require_signature: shp.require_signature,
      print_epl: params[:print_epl] == "1",
      send_email: params[:send_email] == "1",
      ship_date: shp.ship_date.to_s,
      user_id: session[:user_id]
    }
    
    Shipment.where(id: params[:shipment_ids]).update_all(batch_status: "queued", batch_status_message: "")
    BatchShipJob.perform_later(job_params)
    
    redirect_to action: :batch_status, shipment_ids: params[:shipment_ids].join(".")
  end
  
  
  def batch_status
    @shipments = Shipment.where(id: params[:shipment_ids].split("."))
    
    respond_to do |format|
      format.html
      format.json { render json: @shipments, only: [:id, :status, :batch_status, :batch_status_message] }
    end
  end
  
  
  def create_ep_shipment(shipment)
		if shipment.packaging_type == 'YOUR PACKAGING'
			parcel = {
          :length => shipment.package_length, 
          :width => shipment.package_width,
          :height => shipment.package_height,
          :weight => shipment.package_weight * 16.0
        }
		else
			parcel = {
				:predefined_package => shipment.packaging_type,
				:weight => shipment.package_weight * 16.0
			}
		end
    
    options = { 
      :print_custom_1 => shipment.to_s,
      :date_advance => (shipment.ship_date - Date.today).to_i
    }
    options[:delivery_confirmation] = 'SIGNATURE' if shipment.require_signature
    
    EasyPost.api_key = Cache.setting(shipment.order.domain_id, :shipping, 'EasyPost API Key')
    response = EasyPost::Shipment.create(
        :to_address => {
          :name => shipment.recipient_name,
          :company => shipment.recipient_company,
          :street1 => shipment.recipient_street1,
          :street2 => shipment.recipient_street2,
          :city => shipment.recipient_city,
          :state => shipment.recipient_state,
          :zip => shipment.recipient_zip,
          :country => shipment.recipient_country,
          :phone => shipment.order.contact_phone,
          :email => shipment.order.notify_email
        },
        :from_address => {
          :company => shipment.ship_from_company,
          :street1 => shipment.ship_from_street1,
          :city => shipment.ship_from_city,
          :state => shipment.ship_from_state,
          :zip => shipment.ship_from_zip,
          :country => shipment.ship_from_country,
          :phone => shipment.ship_from_phone,
          :email => shipment.ship_from_email
        },
        :parcel => parcel,
        :options => options
    ) 
    
    shipment.copy_easy_post(response)
    response
  end


  private

    def shipment_params
      params.require(:shipment).permit!
    end

end

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
    @shipment.save
  
    OrderHistory.create order_id: @shipment.order_id,
                              user_id: current_user.id,
                              event_type: 'package_shipped',
                              amount: @shipment.ship_cost,
                              system_name: response[:selected_rate][:carrier],
                              identifier: @shipment.tracking_number,
                              comment:  response[:selected_rate][:service]

    @shipment.order.update_attribute(:status, 'shipped')
    redirect_to admin_store_shipment_path(@shipment)
  end
  
  # Creates an EasyPost shipment object which contains rates
  def batch
    @shipment_params = Shipment.new(shipment_params)
    @shipments = Shipment.where(id: params[:shipment_id])
    
    if @shipment_params[:packaging_type].blank? || @shipment_params[:carrier].blank?
      flash[:error] = "Please specify a carrier/packaging type"
      return redirect_to :back
    end
    
    
    debug_str = "<pre>"
    
    @shipments.each do |shp|
      debug_str += "\n" + shp.to_s + "\t" + shp.recipient_name + "\t" + shp.recipient_city + "\t" + shp.recipient_state
      
      shp.assign_attributes(
        packaging_type: @shipment_params.packaging_type,
        package_length: @shipment_params.package_length,
        package_width: @shipment_params.package_width,
        package_height: @shipment_params.package_height,
        package_weight: @shipment_params.package_weight,
        ship_date: @shipment_params.ship_date,
        require_signature: @shipment_params.require_signature
      )

      EasyPost.api_key = Cache.setting(shp.order.domain_id, :shipping, 'EasyPost API Key')
      begin
        ep_shipment = create_ep_shipment(shp)
        selected_rate = ep_shipment.lowest_rate(carriers = [@shipment_params.carrier])
        debug_str += ":\t" + selected_rate[:carrier] + " " + selected_rate[:service] + " " + selected_rate[:rate] 
        #next
        reply = ep_shipment.buy(rate: selected_rate)
        
        shp.copy_easy_post(reply)
        shp.status = 'shipped'
        shp.fulfilled_by_id = session[:user_id]
        shp.save
  
        OrderHistory.create order_id: shp.order_id,
                                  user_id: current_user.id,
                                  event_type: 'package_shipped',
                                  amount: shp.ship_cost,
                                  system_name: reply[:selected_rate][:carrier],
                                  identifier: shp.tracking_number,
                                  comment:  reply[:selected_rate][:service]

        shp.order.update_attribute(:status, 'shipped')
        
        if params[:print_epl] == "1"
          # download label
          label_reply = ep_shipment.label({'file_format' => "epl2"})
      
          # download label
          label_url = label_reply[:postage_label]["label_epl2_url"]
          label_data = Net::HTTP.get(URI.parse(label_url))
      
          ip_addr = Cache.setting(shp.order.domain_id, :shipping, 'Thermal Printer IP')
          s = TCPSocket.new(ip_addr, 9100)
          s.send label_data, 0
          s.close
          debug_str += "\t label printed"
        end
        
        if params[:send_email] == "1"
          unless shp.order.notify_email.include?("marketplace")
            OrderMailer.order_shipped(shp).deliver
            debug_str += "\t emailed #{shp.order.notify_email}"
          end
        end
      rescue => e
        debug_str += e.message 
      end
    end
    
    render text: debug_str
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

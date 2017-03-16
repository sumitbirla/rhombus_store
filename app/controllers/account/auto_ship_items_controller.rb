class Account::AutoShipItemsController < Account::BaseController
  
  def index
    @auto_ship_items = AutoShipItem.where(user_id: session[:user_id]).order(created_at: :desc)
  end
  
	def edit
		@auto_ship_item = AutoShipItem.find_by(id: params[:id], user_id: session[:user_id])
    
    respond_to do |format|
      format.html
      format.js
    end
	end

	def update
		@auto_ship_item = AutoShipItem.find_by(id: params[:id], user_id: session[:user_id])
		
		respond_to do |format|
      if @auto_ship_item.update(auto_ship_item_params)
        format.html { redirect_to :back }
        format.js
        format.json { render json: { status: 'ok', object: @pbx_user } }
      else
        format.html do 
         @autoship_items = AutoShipItem.where(user_id: session[:user_id]).order(created_at: :desc)
		     render 'index'
        end
        format.js
        format.json do
          render json: { status: 'error', 
                         errors: @auto_ship_item.errors.full_messages, 
                         object: @auto_ship_item }
        end
      end
    end
	end
  
  
	private
  
    def auto_ship_item_params
      params.require(:auto_ship_item).permit(:status, :quantity, :days, :next_ship_date)
    end
  
end

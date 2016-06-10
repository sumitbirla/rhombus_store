class Admin::Store::AutoShipItemsController < Admin::BaseController
  
  def index
    @auto_ship_items = AutoShipItem.joins(:user).includes(:user).order(sort_column + " " + sort_direction).page(params[:page])
    @auto_ship_items = @auto_ship_items.where(status: :active) unless (params[:item_type] == "all" || params[:q])
  end
  
  
  def new
    @auto_ship_item = AutoShipItem.new(next_ship_date: Date.today, quantity: 1, status: :active, user_id: params[:user_id])
    render 'edit'
  end

  def create
    @auto_ship_item = AutoShipItem.new(auto_ship_item_params)
    
    if @auto_ship_item.save
      redirect_to action: 'index', notice: 'AutoShipItem was successfully created.'
    else
      render 'edit'
    end
  end

  def edit
    @auto_ship_item = AutoShipItem.find(params[:id])
  end

  def update
    @auto_ship_item = AutoShipItem.find(params[:id])
    
    if @auto_ship_item.update(auto_ship_item_params)
      redirect_to action: 'index', notice: 'AutoShipItem was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @auto_ship_item = AutoShipItem.find(params[:id])
    @auto_ship_item.destroy
    redirect_to action: 'index', notice: 'AutoShipItem has been deleted.'
  end
  
  private
  
    def auto_ship_item_params
      params.require(:auto_ship_item).permit!
    end
    
    def sort_column
      params[:sort] || "next_ship_date"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  
end

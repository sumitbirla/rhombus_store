class Admin::Inventory::InventoryLocationsController < Admin::BaseController
  
  def index
    @inventory_locations = InventoryLocation.order(sort_column + ' ' + sort_direction).paginate(page: params[:page], per_page: @per_page)
  end
  
  def new
    @inventory_location = InventoryLocation.new
    render 'edit'
  end

  def create
    @inventory_location = InventoryLocation.new(inventory_location_params)
    
    if @inventory_location.save
      redirect_to action: 'index'
    else
      render 'edit'
    end
  end

  def edit
    @inventory_location = InventoryLocation.find(params[:id])
  end

  def update
    @inventory_location = InventoryLocation.find(params[:id])
    
    if @inventory_location.update(inventory_location_params)
      redirect_to action: 'index'
    else
      render 'edit'
    end
  end

  def destroy
    @inventory_location = InventoryLocation.find(params[:id])
    @inventory_location.destroy
    redirect_to :back
  end
  
  
  private
  
    def inventory_location_params
      params.require(:inventory_location).permit!
    end
    
    def sort_column
      params[:sort] || "name"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  
  
end

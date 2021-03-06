class Admin::Inventory::InventoryItemsController < Admin::BaseController

  def index
    @inventory_items = InventoryItem.includes(:inventory_location)
                           .joins(:inventory_transaction)
                           .where("inv_transactions.archived = ?", false)
                           .order(sort_column + ' ' + sort_direction)
                           .select("sku, sum(quantity) as quantity, lot, expiration, inventory_location_id")

    if params[:group] == 'location'
      @inventory_items = @inventory_items.group(:inventory_location_id, :sku, :lot)
    else
      @inventory_items = @inventory_items.group(:sku, :lot)
    end

    respond_to do |format|
      format.html { @inventory_items = @inventory_items.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data InventoryItem.to_csv(@inventory_items) }
    end
  end

  def new
    @inventory_item = InventoryItem.new
    render 'edit'
  end

  def create
    @inventory_item = InventoryItem.new(inventory_item_params)
    @inventory_item.user_id = session[:user_id]

    if @inventory_item.save
      redirect_to action: 'index'
    else
      render 'edit'
    end
  end

  def edit
    @inventory_item = InventoryItem.find(params[:id])
  end

  def update
    @inventory_item = InventoryItem.find(params[:id])

    if @inventory_item.update(inventory_item_params)
      redirect_to action: 'index'
    else
      render 'edit'
    end
  end

  def destroy
    @inventory_item = InventoryItem.find(params[:id])
    @inventory_item.destroy
    redirect_back(fallback_location: admin_root_path)
  end


  private

  def inventory_item_params
    params.require(:inventory_item).permit!
  end

  def sort_column
    params[:sort] || "sku"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end


end

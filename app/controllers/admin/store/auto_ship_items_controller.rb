class Admin::Store::AutoShipItemsController < Admin::BaseController

  def index
    authorize AutoShipItem.new

    @selected_status = params[:status].presence || "active"
    @auto_ship_items = AutoShipItem.joins(:user).includes(:user, :product).order(sort_column + " " + sort_direction)
    @auto_ship_items = @auto_ship_items.where(status: @selected_status)

    respond_to do |format|
      format.html { @auto_ship_items = @auto_ship_items.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data AutoShipItem.to_csv(@auto_ship_items) }
    end
  end


  def new
    @auto_ship_item = authorize AutoShipItem.new(next_ship_date: Date.today, quantity: 1, status: :active, user_id: params[:user_id])
    render 'edit'
  end

  def create
    @auto_ship_item = authorize AutoShipItem.new(auto_ship_item_params)

    if @auto_ship_item.save
      redirect_to action: 'index', notice: 'AutoShipItem was successfully created.'
    else
      render 'edit'
    end
  end

  def edit
    @auto_ship_item = authorize AutoShipItem.find(params[:id])
  end

  def update
    @auto_ship_item = authorize AutoShipItem.find(params[:id])

    if @auto_ship_item.update(auto_ship_item_params)
      redirect_to action: 'index', notice: 'AutoShipItem was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @auto_ship_item = authorize AutoShipItem.find(params[:id])
    @auto_ship_item.destroy
    redirect_back(fallback_location: admin_root_path)
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

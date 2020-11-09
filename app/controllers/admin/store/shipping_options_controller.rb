class Admin::Store::ShippingOptionsController < Admin::BaseController

  def index
    @shipping_options = ShippingOption.where(domain: cookies[:domain_id]).order(:name)

    respond_to do |format|
      format.html { @shipping_options = @shipping_options.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data ShippingOption.to_csv(@shipping_options) }
    end
  end

  def new
    @shipping_option = ShippingOption.new name: 'New shipping_option'
    render 'edit'
  end

  def create
    @shipping_option = ShippingOption.new(shipping_option_params)
    @shipping_option.domain_id = cookies[:domain_id]

    if @shipping_option.save
      redirect_to action: 'index', notice: 'Shipping Option was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @shipping_option = ShippingOption.find(params[:id])
  end

  def edit
    @shipping_option = ShippingOption.find(params[:id])
  end

  def update
    @shipping_option = ShippingOption.find(params[:id])

    if @shipping_option.update(shipping_option_params)
      redirect_to action: 'index', notice: 'Shipping Option was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @shipping_option = ShippingOption.find(params[:id])
    @shipping_option.destroy
    redirect_to action: 'index', notice: 'Shipping Option has been deleted.'
  end


  private

  def shipping_option_params
    params.require(:shipping_option).permit!
  end
end

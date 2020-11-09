class Admin::Store::ProductShippingRatesController < Admin::BaseController

  def index
    @product_shipping_rates = ProductShippingRate.order(:code)

    respond_to do |format|
      format.html { @product_shipping_rates = @product_shipping_rates.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data ProductShippingRate.to_csv(@product_shipping_rates) }
    end
  end

  def new
    @product_shipping_rate = ProductShippingRate.new
    render 'edit'
  end

  def create
    @product_shipping_rate = ProductShippingRate.new(product_shipping_rate_params)

    if @product_shipping_rate.save
      redirect_to action: 'index', notice: 'Shipping Option was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @product_shipping_rate = ProductShippingRate.find(params[:id])
  end

  def edit
    @product_shipping_rate = ProductShippingRate.find(params[:id])
  end

  def update
    @product_shipping_rate = ProductShippingRate.find(params[:id])

    if @product_shipping_rate.update(product_shipping_rate_params)
      redirect_to action: 'index', notice: 'Shipping Option was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @product_shipping_rate = ProductShippingRate.find(params[:id])
    @product_shipping_rate.destroy
    redirect_to action: 'index', notice: 'Shipping Option has been deleted.'
  end


  private

  def product_shipping_rate_params
    params.require(:product_shipping_rate).permit!
  end
end

class ProductsController < ActionController::Base
  def show
    @product = Cache.product(params[:slug])
  end
end

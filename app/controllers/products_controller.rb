class ProductsController < ApplicationController
  def show
    @product = StoreCache.product(params[:slug])
    
    if @product.nil?
      flash.now[:error] = "The item you are looking for was not found."
      return render "error_page", status: 404 
    end
  end
end

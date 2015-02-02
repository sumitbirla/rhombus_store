class ProductsController < ApplicationController
  def show
    @product = StoreCache.product(params[:slug])
  end
end

class ProductsController < ApplicationController
  def show
    @product = Cache.product(params[:slug])
  end
end

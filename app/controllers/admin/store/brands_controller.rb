class Admin::Store::BrandsController < Admin::BaseController
  
  def index
    @brands = Brand.order(:name)
    
    respond_to do |format|
      format.html  { @brands = @brands.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Brand.to_csv(@brands) }
    end
  end

  def new
    @brand = Brand.new name: 'New brand'
    render 'edit'
  end

  def create
    @brand = Brand.new(brand_params)
    
    if @brand.save
      redirect_to action: 'index', notice: 'Brand was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @brand = Brand.find(params[:id])
  end

  def edit
    @brand = Brand.find(params[:id])
  end

  def update
    @brand = Brand.find(params[:id])
    
    if @brand.update(brand_params)
      redirect_to action: 'index', notice: 'Brand was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @brand = Brand.find(params[:id])
    @brand.destroy
    redirect_to action: 'index', notice: 'Brand has been deleted.'
  end
  
  
  private
  
    def brand_params
      params.require(:brand).permit!
    end
end

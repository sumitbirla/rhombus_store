class Admin::Store::BrandsController < Admin::BaseController
  
  def index
    authorize Brand.new
    @brands = Brand.order(:name)
		@counts = Brand.joins(:products)
									 .group(:id)
									 .count("store_products.id")
    
    respond_to do |format|
      format.html  { @brands = @brands.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Brand.to_csv(@brands) }
    end
  end

  def new
    @brand = authorize Brand.new(name:'New Brand')
    render 'edit'
  end

  def create
    @brand = authorize Brand.new(brand_params)
    
    if @brand.save
      redirect_to action: 'index', notice: 'Brand was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @brand = authorize Brand.find(params[:id])
  end

  def edit
    @brand = authorize Brand.find(params[:id])
  end

  def update
    @brand = authorize Brand.find(params[:id])
    
    if @brand.update(brand_params)
      redirect_to action: 'index', notice: 'Brand was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
		brand = authorize Brand.find(params[:id])
		
		begin 	
    	brand.destroy
    	flash[:success] = 'Brand has been deleted.'
		rescue => e
			flash[:error] = e.message
		end
		
		redirect_back(fallback_location: admin_root_path)
  end
  
  
  private
  
    def brand_params
      params.require(:brand).permit!
    end
end

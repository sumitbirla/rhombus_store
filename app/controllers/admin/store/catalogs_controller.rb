class Admin::Store::CatalogsController < Admin::BaseController
  
  def index
    authorize Catalog.new
    @catalogs = Catalog.order("created_at DESC")
    
    respond_to do |format|
      format.html  { @catalogs = @catalogs.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Catalog.to_csv(@catalogs) }
    end
  end

  def new
    @catalog = authorize Catalog.new(name: 'New Catalog')
    render 'edit'
  end

  def create
    @catalog = authorize Catalog.new(catalog_params)
    
    if @catalog.save
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Catalog was successfully created.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def show
    @catalog = authorize Catalog.find(params[:id])
  end

  def edit
    @redirect = params[:redirect]
    @catalog = authorize Catalog.find(params[:id])
  end

  def update
    @catalog = authorize Catalog.find(params[:id])
    
    if @catalog.update(catalog_params)
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Catalog was successfully updated.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def destroy
    @catalog = authorize Catalog.find(params[:id])
    @catalog.destroy
    redirect_back(fallback_location: admin_root_path)
  end
  
  
  private
  
    def catalog_params
      params.require(:catalog).permit!
    end
  
end

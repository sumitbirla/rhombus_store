class Admin::Store::UpcController < Admin::BaseController
  
  def index
    @upcs = Upc.order(:code)
    @upcs = @upcs.where("item IS NOT NULL AND item <> ''") if params[:allocated] == "1"
    @upcs = @upcs.where("item IS NULL OR item = ''") if params[:allocated] == "0"
    @upcs = @upcs.where("code LIKE ? OR item LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") unless params[:q].nil?
    
    respond_to do |format|
      format.html  { @upcs = @upcs.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Upc.to_csv(@upcs) }
    end
  end

  def new
    @upc = Upc.new
  end

  def create
    @upc = Upc.new(upc_params)
    
    if @upc.save
      redirect_to action: 'index', notice: 'Upc was successfully created.'
    else
      render 'new'
    end
  end

  def show
    @upc = Upc.find(params[:id])
  end

  def edit
    @upc = Upc.find(params[:id])
  end

  def update
    @upc = Upc.find(params[:id])
    
    if @upc.update(upc_params)
      redirect_to action: 'index', notice: 'Upc was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @upc = Upc.find(params[:id])
    @upc.destroy
    redirect_to action: 'index', notice: 'Upc has been deleted.'
  end
  
  
  def allocate_batch
    # CHECK IF TAG HAS BEEN USED PREVIOUSLY
    if params[:tag].blank? || Upc.exists?(item: params[:tag])
      flash[:error] = "The tag has already been used.  Please specify a different tag."
      return redirect_back(fallback_location: admin_root_path)
    end
    
    # CHECK IF ENOUGH UPC codes AVAILABLE
    qty = params[:quantity].to_i
    list = Upc.where("item IS NULL OR item = ''").limit(qty)
    if list.length < qty
      flash[:error] = "Not enough available UPCs.  Requested: #{params[:quantity]},  available: #{list.length}"
      return redirect_back(fallback_location: admin_root_path)
    end
      
    # ALLOCATE
    Upc.where(id: list.collect(&:id)).update_all(item: params[:tag], updated_at: DateTime.now)
    flash[:info] = "#{params[:quantity]} UPC's allocated with tag '#{params[:tag]}'"
      
    redirect_to action: :index, q: params[:tag]
  end
  
  
  private
  
    def upc_params
      params.require(:upc).permit!
    end
end

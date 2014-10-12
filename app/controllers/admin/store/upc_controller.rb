class Admin::Store::UpcController < Admin::BaseController
  
  def index
    @upcs = Upc.page(params[:page])
    @upcs = @upcs.where("code LIKE '%#{params[:q]}%' OR item LIKE '%#{params[:q]}%'") unless params[:q].nil?
    
    respond_to do |format|
      format.html
      format.csv { send_data Upc.to_csv }
    end
  end

  def new
    @upc = Upc.new
    render 'edit'
  end

  def create
    @upc = Upc.new(upc_params)
    
    if @upc.save
      redirect_to action: 'index', notice: 'Upc was successfully created.'
    else
      render 'edit'
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
  
  
  private
  
    def upc_params
      params.require(:upc).permit(:code, :item)
    end
end

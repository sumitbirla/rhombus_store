class Admin::Inventory::SublocationsController < Admin::BaseController
  
  def new
    @sublocation = Sublocation.new zone: 'A', location_id: params[:location_id]
    render 'edit'
  end

  def create
    @sublocation = Sublocation.new(sublocation_params)
    
    if @sublocation.save
      redirect_to action: 'sublocations', controller: 'admin/cms/locations', id: @sublocation.location_id
    else
      render 'edit'
    end
  end

  def edit
    @sublocation = Sublocation.find(params[:id])
  end

  def update
    @sublocation = Sublocation.find(params[:id])
    
    if @sublocation.update(sublocation_params)
      redirect_to action: 'sublocations', controller: 'admin/cms/locations', id: @sublocation.location_id
    else
      render 'edit'
    end
  end

  def destroy
    @sublocation = Sublocation.find(params[:id])
    @sublocation.destroy
    redirect_to :back
  end
  
  
  private
  
    def sublocation_params
      params.require(:sublocation).permit!
    end
  
  
end

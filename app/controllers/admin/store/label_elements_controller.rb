class Admin::Store::LabelElementsController < Admin::BaseController
  
  def index
    @label_elements = LabelElement.order("created_at DESC")
    
    respond_to do |format|
      format.html  { @label_elements = @label_elements.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data LabelElement.to_csv(@label_elements) }
    end
  end

  def new
    @redirect = params[:redirect]
    @label_element = LabelElement.new name: 'New Label Element', product_id: params[:product_id]
    render 'edit'
  end

  def create
    @label_element = LabelElement.new(label_element_params)
    
    if @label_element.save
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Label Element was successfully created.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def show
    @label_element = LabelElement.find(params[:id])
  end

  def edit
    @redirect = params[:redirect]
    @label_element = LabelElement.find(params[:id])
  end

  def update
    @label_element = LabelElement.find(params[:id])
    
    if @label_element.update(label_element_params)
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Label Element was successfully updated.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def destroy
    @label_element = LabelElement.find(params[:id])
    @label_element.destroy
    redirect_to :back
  end
  
  
  private
  
    def label_element_params
      params.require(:label_element).permit!
    end
  
  
end

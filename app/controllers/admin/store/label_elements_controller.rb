class Admin::Store::LabelElementsController < Admin::BaseController
  
  def index
    authorize LabelElement
    @label_elements = LabelElement.order(created_at: :desc)
    
    respond_to do |format|
      format.html  { @label_elements = @label_elements.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data LabelElement.to_csv(@label_elements) }
    end
  end

  def new
    @redirect = params[:redirect]
    @label_element = authorize LabelElement.new(name: 'New Label Element', product_id: params[:product_id])
    render 'edit'
  end

  def create
    @label_element = authorize LabelElement.new(label_element_params)
    
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
    @label_element = authorize LabelElement.find(params[:id])
  end

  def edit
    @redirect = params[:redirect]
    @label_element = authorize LabelElement.find(params[:id])
  end

  def update
    @label_element = authorize LabelElement.find(params[:id])
    
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
    @label_element = authorize LabelElement.find(params[:id])
    @label_element.destroy
    redirect_to :back
  end
  
  
  private
  
    def label_element_params
      params.require(:label_element).permit!
    end
  
  
end

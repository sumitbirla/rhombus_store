class Admin::Store::LabelSheetsController < Admin::BaseController

  def index
    @label_sheets = LabelSheet.paginate(page: params[:page], per_page: @per_page).order('name')
  end

  def new
    @label_sheet = LabelSheet.new name: 'New sheet name'
    render 'edit'
  end

  def create
    @label_sheet = LabelSheet.new(label_sheet_params)

    if @label_sheet.save
      redirect_to action: 'index', notice: 'Label Sheet was successfully created.'
    else
      render 'edit'
    end
  end

  def edit
    @label_sheet = LabelSheet.find(params[:id])
  end

  def update
    @label_sheet = LabelSheet.find(params[:id])

    if @label_sheet.update(label_sheet_params)
      redirect_to action: 'index', notice: 'Label Sheet was successfully created.'
    else
      render 'edit'
    end
  end

  def destroy
    @label_sheet = LabelSheet.find(params[:id])
    @label_sheet.destroy
    redirect_to action: 'index', notice: 'Label Sheet has been deleted.'
  end


  private

  def label_sheet_params
    params.require(:label_sheet).permit(:name, :width, :height, :dpi)
  end
end

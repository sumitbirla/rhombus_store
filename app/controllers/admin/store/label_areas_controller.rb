class Admin::Store::LabelAreasController < Admin::BaseController

  def new
    @label_area = LabelArea.new label_sheet_id: params[:label_sheet_id], name: 'Area #'
    render 'edit'
  end

  def create
    @label_area = LabelArea.new(label_area_params)

    if @label_area.save
      redirect_to edit_admin_store_label_sheet_path(@label_area.label_sheet)
    else
      render 'edit'
    end
  end

  def edit
    @label_area = LabelArea.find(params[:id])
  end

  def update
    @label_area = LabelArea.find(params[:id])

    if @label_area.update(label_area_params)
      redirect_to edit_admin_store_label_sheet_path(@label_area.label_sheet)
    else
      render 'edit'
    end
  end

  def destroy
    LabelArea.delete(params[:id])
    redirect_back(fallback_location: admin_root_path)
  end


  private

  def label_area_params
    params.require(:label_area).permit(:label_sheet_id, :name, :top, :left, :width, :height)
  end

end

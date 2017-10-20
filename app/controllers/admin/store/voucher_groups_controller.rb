class Admin::Store::VoucherGroupsController < Admin::BaseController
  
  def index
    authorize VoucherGroup
    @voucher_groups = VoucherGroup.order(created_at: :desc)
    
    respond_to do |format|
      format.html  { @voucher_groups = @voucher_groups.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data VoucherGroup.to_csv(@voucher_groups) }
    end
  end

  def new
    @voucher_group = authorize VoucherGroup.new(name: 'New voucher group')
    render 'edit'
  end

  def create
    @voucher_group = authorize VoucherGroup.new(voucher_group_params)
    
    if @voucher_group.save
      redirect_to action: 'index', notice: 'VoucherGroup was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @voucher_group = authorize VoucherGroup.find(params[:id])
  end

  def edit
    @voucher_group = authorize VoucherGroup.find(params[:id])
  end

  def update
    @voucher_group = authorize VoucherGroup.find(params[:id])
    
    if @voucher_group.update(voucher_group_params)
      redirect_to action: 'index', notice: 'VoucherGroup was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @voucher_group = authorize VoucherGroup.find(params[:id])
    @voucher_group.destroy
    redirect_to action: 'index', notice: 'VoucherGroup has been deleted.'
  end
  
  def create_vouchers
    authorize Voucher, :create?
    
    group_id = params[:id].to_i
    num = params[:num].to_i
    len = params[:len].to_i / 2
    
    num.times.each do
      Voucher.create voucher_group_id: group_id, code: SecureRandom.hex(len)
    end
    
    redirect_to action: 'show', id: group_id
  end
  
  
  private
  
    def voucher_group_params
      params.require(:voucher_group).permit!
    end
  
end

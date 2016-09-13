class Admin::Store::ProductsController < Admin::BaseController
  
  def index
    @products = Product.includes(:brand).order(sort_column + " " + sort_direction)
    @products = @products.where(active: true) unless (params[:product_type] == "all" || params[:q])
    @products = @products.where(brand_id: params[:brand_id]) unless params[:brand_id].blank?
    @products = @products.where("name LIKE '%#{params[:q]}%' OR item_number = '#{params[:q]}'") unless params[:q].nil?
    
    respond_to do |format|
      format.html  { @products = @products.page(params[:page]) }
      format.csv { send_data Product.to_csv(@products) }
    end
  end

  def new
    @product = Product.new name: 'New product'
    render 'edit'
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to action: 'show', id: @product.id, notice: 'Product was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @product = Product.find(params[:id])
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    
    if @product.update(product_params)
      Rails.cache.delete @product
      redirect_to action: 'show', id: params[:id], notice: 'Product was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    
    Rails.cache.delete @product
    redirect_to action: 'index', notice: 'Product has been deleted.'
  end
  
  def pictures
    @product = Product.find(params[:id])
  end
  
  def coupons
    @product = Product.find(params[:id])
  end
  
  def categories
    @product = Product.find(params[:id])
  end
  
  def create_categories
    @product = Product.find(params[:id])
    ProductCategory.delete_all product_id: @product.id
    category_ids = params[:category_ids]
    
    category_ids.each do |id|
      ProductCategory.create product_id: @product.id, category_id: id
    end
    
    Rails.cache.delete @product
    redirect_to action: 'show', id: @product.id, notice: 'Product was successfully updated.'
  end
  
  def extra_properties
    @product = Product.find(params[:id])
    5.times { @product.extra_properties.build }
  end
  
  def adjust_prices
    @products = Product.where(active: true)
  end
  
  
  def update_prices
    
    @products = Product.all
    
    params.each do |key, val|
      
      tokens = key.split('-')
      next unless [ 'web', 'distributor', 'retailer', 'msrp', 'map'].include?(tokens[0])
      
      value = val.blank? ? nil : val.to_d
      product_id = tokens[1].to_i
      product = @products.find { |p| p.id == product_id }
      
      product.update_attribute(:price, value) if tokens[0] == 'web' unless product.price == value
      product.update_attribute(:retail_map, value) if tokens[0] == 'map' unless product.retail_map == value
      product.update_attribute(:msrp, value) if tokens[0] == 'msrp' unless product.msrp == value
      
    end
    
    flash[:notice] = "Prices have been updated"
    redirect_to :back
  end
  
  
  def item_info
    p = Product.find_by(item_number: params[:sku])
    dd = DailyDeal.find_by(id: params[:sku].sub("DEAL", "").to_i) unless p
    
    if p
      ap = AffiliateProduct.find_by(affiliate_id: params[:affiliate_id], product_id: p.id) unless params[:affiliate_id].blank?
      
      if ap
        return render json: { status: 'ok', 
                            sku: ap.item_number || p.sku, 
                            description: ap.description.presence || p.name_with_option, 
                            price: ap.price,
                            moc: ap.minimum_order_quantity }
      else
        return render json: { status: 'ok', 
                            product_id: p.id, 
                            description: p.name_with_option, 
                            price: p.price,
                            case_quantity: p.case_quantity }
      end
        
    elsif dd
      return render json: { status: 'ok', 
                            daily_deal_id: dd.id, 
                            description: dd.title, 
                            price: dd.deal_price, 
                            dealer_price: dd.deal_price }
    else
      sku, affiliate_code, variant = params[:sku].split('-')
      p = Product.find_by(sku: sku)
      aff = Affiliate.find_by(code: affiliate_code)
      
      unless p.nil? || aff.nil?
        return render json: { status: 'ok', 
                              product_id: p.id, 
                              affiliate_id: aff.id, 
                              affiliate_name: aff.name, 
                              variation: variant, 
                              description: p.name_with_option, 
                              price: p.price }
      end
    end
    
    render json: { status: 'not found' }
  end
  
  def clone
    @product = Product.find(params[:id]).dup
    @product.slug += "-clone"
    render 'edit'
  end
  
  
  private
  
    def product_params
      params.require(:product).permit!
    end
    
    def sort_column
      params[:sort] || "title"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  
end

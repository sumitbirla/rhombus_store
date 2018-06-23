class Admin::Store::ProductsController < Admin::BaseController
  
  def index
    authorize Product.new
    
    q = params[:q]
    @products = Product.includes(:brand).order(sort_column + " " + sort_direction)
    
    unless q.nil?
      @products = @products.where("name LIKE '%#{q}%' OR item_number = '#{q}' OR SKU = '#{q}'") 
    else
      @products = @products.where(active: true) unless params[:product_type] == "all"
      @products = @products.where(brand_id: (params[:brand_id].blank? ? nil : params[:brand_id])) unless params[:brand_id] == 'all'
    end
      
    respond_to do |format|
      format.html  { @products = @products.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Product.to_csv(@products) }
    end
  end

  def new
    @product = authorize Product.new(name: 'New product')
    render 'edit'
  end

  def create
    @product = authorize Product.new(product_params)
    
    if @product.save
      redirect_to action: 'show', id: @product.id, notice: 'Product was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @product = authorize Product.find(params[:id])
  end

  def edit
    @product = authorize Product.find(params[:id])
  end

  def update
    @product = authorize Product.find(params[:id])

    if @product.update(product_params)
      Rails.cache.delete @product
      Rails.cache.delete("featured-product")
      redirect_to action: 'show', id: params[:id], notice: 'Product was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @product = authorize Product.find(params[:id])
    @product.destroy
    
    Rails.cache.delete @product
    redirect_to action: 'index', notice: 'Product has been deleted.'
  end
  
  def pictures
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def coupons
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def categories
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def create_categories
    @product = Product.find(params[:id])
    authorize @product, :update?
    
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
    authorize @product, :show?
    5.times { @product.extra_properties.build }
  end
  
  def label_elements
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def adjust_prices
    authorize Product, :update?
    @products = Product.where(active: true)
  end
  
  
  def update_prices
    authorize Product, :update?
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
    sku = params[:sku]
    aff_id = params[:affiliate_id]
    
    # handle daily deals first
    if sku.starts_with?('DEAL')
      dd = DailyDeal.find_by(id: sku.sub("DEAL", "").to_i)
      render json: { status: 'not found' } if dd.nil?
      
      return render json: { status: 'ok', 
                            daily_deal_id: dd.id, 
                            description: dd.title, 
                            price: dd.deal_price, 
                            dealer_price: dd.deal_price,
                            moc: 1 }
    end
    
    # check if this is an itemnum-affcode-variant format SKU  
    if sku.count('-') == 2 && sku.split('-').last.length == 3
      sku, affiliate_code, variant = sku.split('-')
      aff = Affiliate.find_by(code: affiliate_code)
    end
    
    p = Product.find_by("item_number = ? OR upc = ?", sku, sku)
    render json: { status: 'not found' } if p.nil?
    
    ap = AffiliateProduct.find_by(affiliate_id: aff_id, product_id: p.id) unless aff_id.blank?
  
    render json: { status: 'ok', 
                   product_id: p.id, 
                   affiliate_id: (aff ? aff.id : nil), 
                   affiliate_name: (aff ? aff.name : nil), 
                   variation: variant, 
                   sku: (ap ? (ap.item_number || p.sku) : p.sku), 
                   description: (ap ? (ap.description.presence || p.name_with_option) : p.name_with_option), 
                   price: (ap ? ap.price : p.price),
                   moc: (ap ? ap.minimum_order_quantity : 1) }
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

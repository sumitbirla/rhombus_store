module StoreCache
    
  def self.product(slug) 
    Rails.cache.fetch("product:#{slug}") do 
      Product.includes(:categories, :pattributes, [pattributes: :attribute], :brand, :pictures, :comments).where(slug: slug, hidden: false).first
    end
  end
  
  
  def self.product_list(category_slug)
    Rails.cache.fetch("product-list:#{category_slug}") do
      c = Category.where(slug: category_sluf, enabled: true, entity_type: :product)
      unless c.nil?
        
      end
    end
  end
  
  def self.all_affiliate_products(slug)
    Rails.cache.fetch("ap-list:#{slug}") do
      aff = Affiliate.find_by(slug: slug)
      AffiliateProduct.includes(:product).where(affiliate_id: aff.id).where("product.active=1 AND product.hidden=0")
    end
  end
  
  def self.affiliate_products(affiliate_slug, category_slug)
    Rails.cache.fetch("affiliate-products-#{affiliate_slug}-#{category_slug}") do
      
      cat = Category.find_by(slug: category_slug, entity_type: :product)
      aff = Affiliate.find_by(slug: affiliate_slug)

      new_list = []
      ap_list = AffiliateProduct.includes(:product, [product: :product_categories]).where(affiliate_id: aff.id)
      
      ap_list.each do |ap|
        new_list << ap if ap.product.product_categories.any? { |pc| pc.category_id == cat.id }
      end
      
      new_list
    end
  end
  
  def self.affiliate_product(affiliate, product_slug)
    affiliate = Affiliate.find_by(slug: affiliate) if affiliate.class.name == "String"
    
    Rails.cache.fetch("ap:#{affiliate.slug}:#{product_slug}") do
      AffiliateProduct
            .includes(:product, [product: :pictures, product: :pattributes])
            .find_by(affiliate_id: affiliate.id, product_id: Product.select(:id).where(slug: product_slug))
    end
  end
  
  
  # Daily deals
  
  def self.featured_deal
    Rails.cache.fetch("featured-deal") do 
      DailyDeal.where(active: true)
                    .where("start_time < NOW()")
                    .where("end_time > NOW()")
                    .order("start_time DESC").first
    end
  end
  
end
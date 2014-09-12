Rails.application.routes.draw do
  
  get 'cart/remove/:id' => 'cart#remove'
  post 'cart/update'
  post 'cart/add'
  post 'cart/applycode'
  get 'cart/checkout'
  get 'cart/review'
  post 'cart/review' => 'cart#submit'
  post 'cart/checkout' => 'cart#checkout_update'
  get 'cart/submitted'
  get 'cart' => 'cart#index'
  get "products/:slug" => 'products#show'
  get 'resize' => 'images#resize'
  get 'images/resize'
  get "paypal_express/checkout"
  get "paypal_express/review"
  get 'barcode' => 'barcode#generate'
  
  get '/daily_deals/:slug' => 'daily_deals#show'
  
  
  namespace :account do
    resources :orders
    resources :payment_methods do
      member do
        get 'primary' => 'payment_methods#primary'
      end
    end
    resources :vouchers
  end
  
  
  
  namespace :admin do 
    
    namespace :system do 
      resources :affiliates do
        member do
          get 'products' => 'affiliates#products'
          post 'products_remove' => 'affiliates#remove_products'
          post 'products' => 'affiliates#create_products'
        end
      end
    end
    
    namespace :inventory do
      resources :sublocations
      resources :stock
      resources :purchase_orders do
        member do
          get 'items' => 'purchase_orders#items'
          post 'items' => 'purchase_orders#update_items'
          get 'receiving' => 'purchase_orders#receiving'
          post 'items' => 'purchase_orders#update_items'
          post 'receiving' => 'purchase_orders#update_receiving'
        end
      end
      resources :purchase_order_items
      resources :inventory_transactions
    end

    namespace :shipping do
      get 'fedex' => 'fedex#index'
      patch 'fedex' => 'fedex#rates'
      get 'fedex_label' => 'fedex#label'

      get 'ups' => 'ups#index'
      post 'ups' => 'ups#rates'
      get 'ups_label' => 'ups#label'
      
      get 'easy_post' => 'easy_post#index'
      patch 'easy_post' => 'easy_post#rates'
      get 'easy_post_label' => 'easy_post#label'

      get 'stamps/label' => 'stamps#label'
      get 'stamps/void' => 'stamps#void'
      get 'stamps' => 'stamps#index'
      patch 'stamps' => 'stamps#rates'

    end

    # Store Routes
    namespace :store do

      get 'shipments/choose_order'
      get 'products/adjust_prices'
      post 'products/adjust_prices' => 'products#update_prices'

      resources :brands
      resources :products do
        member do
          get 'pictures' => 'products#pictures'
          get 'categories' => 'products#categories'
          get 'attributes' => 'products#attributes'
          get 'coupons' => 'products#coupons'
          post 'categories' => 'products#create_categories'
          post 'attributes' => 'products#create_attributes'
        end
      end
      resources :orders do
        member do
          resources :items
          resources :deal_items
          get 'resend_email' => 'orders#resend_email'
          get 'product_labels' => 'orders#product_labels'
          get 'print_shipping_label' => 'orders#print_shipping_label'
          get 'invoice' => 'orders#invoice'
        end
      end
      resources :coupons
      resources :shipments do
        member do
          get 'product_labels' => 'shipments#product_labels'
          get 'label' => 'shipments#label'
          get 'print' => 'shipments#print'
          get 'packing_slip' => 'shipments#packing_slip'
        end
      end
      resources :tax_rates
      resources :vouchers
      resources :voucher_groups do
        post 'vouchers' => 'voucher_groups#create_vouchers'
      end
      resources :invoice_images
      resources :shipping_options
      resources :upc
      resources :affiliate_products
      resources :label_sheets
      resources :label_areas

      resources :daily_deals do
        member do
          get 'pictures' => 'daily_deals#pictures'
          get 'categories' => 'daily_deals#categories'
          get 'coupons' => 'daily_deals#coupons'
          get 'items' => 'daily_deals#items'
          get 'locations' => 'daily_deals#locations'
          get 'external_coupons' => 'daily_deals#external_coupons'
          post 'categories' => 'daily_deals#create_categories'
          post 'coupons' => 'daily_deals#create_coupon'
          post 'create_external_coupons' => 'daily_deals#create_external_coupons'
          post 'import_external_coupons' => 'daily_deals#import_external_coupons'
          get 'delete_external_coupon' => 'daily_deals#delete_external_coupon'
          get 'delete_all_external_coupons' => 'daily_deals#delete_all_external_coupons'
          get 'export_external_coupons' => 'daily_deals#export_external_coupons'
        end
      end

    end
      
  end
  
end

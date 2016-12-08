class CreateStoreTables < ActiveRecord::Migration
  def change
    
    create_table "store_affiliate_products", force: :cascade do |t|
      t.integer  "affiliate_id",           limit: 4,                                              null: false
      t.integer  "product_id",             limit: 4,                                              null: false
      t.string   "item_number",            limit: 255
      t.decimal  "price",                                precision: 10, scale: 4
      t.integer  "minimum_order_quantity", limit: 4,                              default: 1,     null: false
      t.string   "title",                  limit: 255
      t.text     "description",            limit: 65535
      t.string   "data",                   limit: 255
      t.string   "images",                 limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "category1",              limit: 255
      t.string   "category2",              limit: 255
      t.string   "category3",              limit: 255
      t.integer  "ship_lead_time",         limit: 4,                              default: 14,    null: false
      t.boolean  "hidden",                                                        default: false, null: false
    end

    add_index "store_affiliate_products", ["affiliate_id"], name: "index_affiliate_products_on_affiliate_id", using: :btree
    add_index "store_affiliate_products", ["product_id"], name: "index_affiliate_products_on_product_id", using: :btree

    create_table "store_auto_ship_items", force: :cascade do |t|
      t.integer  "user_id",        limit: 4,                null: false
      t.string   "item_number",    limit: 255,              null: false
      t.integer  "product_id",     limit: 4,                null: false
      t.integer  "affiliate_id",   limit: 4
      t.string   "variation",      limit: 255
      t.string   "description",    limit: 255,              null: false
      t.integer  "quantity",       limit: 4,                null: false
      t.integer  "days",           limit: 4,   default: 30, null: false
      t.date     "last_shipped"
      t.date     "next_ship_date"
      t.string   "status",         limit: 255,              null: false
      t.datetime "created_at",                              null: false
      t.datetime "updated_at",                              null: false
    end

    add_index "store_auto_ship_items", ["affiliate_id"], name: "index_store_auto_ship_items_on_affiliate_id", using: :btree
    add_index "store_auto_ship_items", ["product_id"], name: "index_store_auto_ship_items_on_product_id", using: :btree
    add_index "store_auto_ship_items", ["user_id"], name: "index_store_auto_ship_items_on_user_id", using: :btree

    create_table "store_brands", force: :cascade do |t|
      t.string   "name",       limit: 255
      t.string   "website",    limit: 255
      t.string   "logo",       limit: 255
      t.text     "about",      limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_coupons", force: :cascade do |t|
      t.string   "code",             limit: 255,                            null: false
      t.text     "description",      limit: 65535
      t.integer  "product_id",       limit: 4
      t.integer  "daily_deal_id",    limit: 4
      t.boolean  "free_shipping"
      t.decimal  "discount_amount",                precision: 10, scale: 2
      t.decimal  "discount_percent",               precision: 5,  scale: 2
      t.decimal  "min_order_amount",               precision: 10, scale: 2
      t.integer  "max_uses",         limit: 4
      t.integer  "max_per_user",     limit: 4
      t.integer  "times_used",       limit: 4,                              null: false
      t.datetime "start_time",                                              null: false
      t.datetime "expire_time",                                             null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_coupons", ["product_id"], name: "index_coupons_on_product_id", using: :btree

    create_table "store_daily_deal_categories", force: :cascade do |t|
      t.integer  "daily_deal_id", limit: 4
      t.integer  "category_id",   limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_categories", ["category_id"], name: "index_daily_deal_categories_on_category_id", using: :btree
    add_index "store_daily_deal_categories", ["daily_deal_id"], name: "index_daily_deal_categories_on_daily_deal_id", using: :btree

    create_table "store_daily_deal_coupons", force: :cascade do |t|
      t.string   "code",              limit: 255,                            null: false
      t.text     "description",       limit: 65535
      t.integer  "daily_deal_id",     limit: 4,                              null: false
      t.boolean  "free_shipping",                                            null: false
      t.boolean  "free_order",                                               null: false
      t.decimal  "discount_amount",                 precision: 10, scale: 2
      t.decimal  "discount_percent",                precision: 5,  scale: 2
      t.decimal  "min_order_amount",                precision: 10, scale: 2
      t.integer  "buy_x",             limit: 4
      t.integer  "get_y_free",        limit: 4
      t.integer  "max_uses",          limit: 4
      t.integer  "max_user_per_user", limit: 4
      t.datetime "start_time"
      t.datetime "expire_time"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_coupons", ["daily_deal_id"], name: "index_daily_deal_coupons_on_daily_deal_id", using: :btree

    create_table "store_daily_deal_items", force: :cascade do |t|
      t.integer  "daily_deal_id", limit: 4,                           null: false
      t.integer  "product_id",    limit: 4,                           null: false
      t.integer  "affiliate_id",  limit: 4
      t.string   "variation",     limit: 255
      t.decimal  "unit_cost",                 precision: 8, scale: 2, null: false
      t.integer  "quantity",      limit: 4,                           null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_items", ["affiliate_id"], name: "index_store_daily_deal_items_on_affiliate_id", using: :btree
    add_index "store_daily_deal_items", ["daily_deal_id"], name: "index_daily_deal_items_on_daily_deal_id", using: :btree
    add_index "store_daily_deal_items", ["product_id"], name: "index_daily_deal_items_on_product_id", using: :btree

    create_table "store_daily_deal_locations", force: :cascade do |t|
      t.integer  "daily_deal_id", limit: 4, null: false
      t.integer  "location_id",   limit: 4, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_locations", ["daily_deal_id"], name: "index_daily_deal_locations_on_daily_deal_id", using: :btree
    add_index "store_daily_deal_locations", ["location_id"], name: "index_daily_deal_locations_on_location_id", using: :btree

    create_table "store_daily_deals", force: :cascade do |t|
      t.integer  "affiliate_id",               limit: 4
      t.decimal  "affiliate_remittance",                     precision: 8, scale: 2
      t.boolean  "affiliate_paid",                                                                 null: false
      t.string   "deal_type",                  limit: 255,                           default: "",  null: false
      t.string   "slug",                       limit: 255,                                         null: false
      t.string   "title",                      limit: 255,                                         null: false
      t.datetime "start_time",                                                                     null: false
      t.datetime "end_time",                                                                       null: false
      t.datetime "voucher_expiration"
      t.decimal  "original_price",                           precision: 8, scale: 2,               null: false
      t.decimal  "deal_price",                               precision: 8, scale: 2,               null: false
      t.decimal  "shipping_cost",                            precision: 6, scale: 2, default: 0.0, null: false
      t.text     "conditions",                 limit: 65535
      t.text     "description",                limit: 65535,                                       null: false
      t.string   "short_tag_line",             limit: 255,                                         null: false
      t.text     "redemption_instructions",    limit: 65535
      t.text     "order_specifications",       limit: 65535
      t.string   "theme",                      limit: 255
      t.integer  "max_sales",                  limit: 4
      t.integer  "max_per_user",               limit: 4
      t.integer  "number_sold",                limit: 4,                                           null: false
      t.boolean  "countdown_mode",                                                                 null: false
      t.integer  "sales_before_showing_count", limit: 4
      t.boolean  "active",                                                                         null: false
      t.boolean  "featured",                                                                       null: false
      t.boolean  "allow_photo_upload",                                                             null: false
      t.integer  "facebook_posts",             limit: 4,                                           null: false
      t.integer  "facebook_clicks",            limit: 4,                                           null: false
      t.decimal  "fb_discount",                              precision: 5, scale: 2, default: 0.0, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "uuid",                       limit: 255,                                         null: false
    end

    add_index "store_daily_deals", ["affiliate_id"], name: "index_daily_deals_on_affiliate_id", using: :btree

    create_table "store_external_coupons", force: :cascade do |t|
      t.integer  "daily_deal_id", limit: 4,   null: false
      t.string   "code",          limit: 255, null: false
      t.boolean  "allocated",                 null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_external_coupons", ["daily_deal_id"], name: "index_external_coupons_on_daily_deal_id", using: :btree

    create_table "store_invoice_images", force: :cascade do |t|
      t.integer  "domain_id",  limit: 4, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_label_areas", force: :cascade do |t|
      t.integer  "label_sheet_id", limit: 4
      t.string   "name",           limit: 255,                         null: false
      t.decimal  "top",                        precision: 6, scale: 3, null: false
      t.decimal  "left",                       precision: 6, scale: 3, null: false
      t.decimal  "width",                      precision: 6, scale: 3, null: false
      t.decimal  "height",                     precision: 6, scale: 3, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_label_areas", ["label_sheet_id"], name: "index_label_areas_on_label_sheet_id", using: :btree

    create_table "store_label_elements", force: :cascade do |t|
      t.integer  "product_id",           limit: 4,                            null: false
      t.string   "name",                 limit: 255,                          null: false
      t.string   "type",                 limit: 255,                          null: false
      t.string   "use",                  limit: 255,                          null: false
      t.decimal  "top",                              precision: 6,  scale: 2
      t.decimal  "left",                             precision: 6,  scale: 2
      t.decimal  "width",                            precision: 6,  scale: 2
      t.decimal  "height",                           precision: 6,  scale: 2
      t.string   "background_color",     limit: 255
      t.string   "horizontal_alignment", limit: 255
      t.string   "vertical_alignment",   limit: 255
      t.decimal  "font_size",                        precision: 10
      t.string   "font_color",           limit: 255
      t.string   "font_family",          limit: 255
      t.string   "font_style",           limit: 255
      t.integer  "max_chars",            limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_label_sheets", force: :cascade do |t|
      t.string   "name",       limit: 255,                         null: false
      t.decimal  "width",                  precision: 6, scale: 3, null: false
      t.decimal  "height",                 precision: 6, scale: 3, null: false
      t.integer  "dpi",        limit: 4,                           null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_manifests", force: :cascade do |t|
      t.date     "day",                                            null: false
      t.string   "carrier",          limit: 255,                   null: false
      t.integer  "shipment_count",   limit: 4
      t.string   "batch_id",         limit: 255
      t.text     "result",           limit: 65535
      t.string   "status",           limit: 255,                   null: false
      t.string   "document_url",     limit: 255
      t.boolean  "pickup_requested",               default: false, null: false
      t.datetime "created_at",                                     null: false
      t.datetime "updated_at",                                     null: false
    end

    create_table "store_order_history", force: :cascade do |t|
      t.integer  "order_id",    limit: 4,                                           null: false
      t.integer  "user_id",     limit: 4
      t.string   "event_type",  limit: 255,                            default: "", null: false
      t.decimal  "amount",                    precision: 10, scale: 2
      t.string   "system_name", limit: 255,                                         null: false
      t.string   "identifier",  limit: 255
      t.string   "comment",     limit: 255
      t.binary   "data1",       limit: 65535
      t.binary   "data2",       limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_order_history", ["order_id"], name: "index_order_histories_on_order_id", using: :btree

    create_table "store_order_items", force: :cascade do |t|
      t.integer  "order_id",            limit: 4,                                        null: false
      t.integer  "product_id",          limit: 4
      t.integer  "daily_deal_id",       limit: 4
      t.integer  "affiliate_id",        limit: 4
      t.string   "external_id",         limit: 255
      t.string   "variation",           limit: 255
      t.integer  "quantity",            limit: 4,                                        null: false
      t.decimal  "unit_price",                      precision: 12, scale: 4,             null: false
      t.string   "item_number",         limit: 32,                                       null: false
      t.string   "item_description",    limit: 255,                                      null: false
      t.integer  "autoship_months",     limit: 4,                            default: 0, null: false
      t.string   "uploaded_file",       limit: 255
      t.string   "upload_file_preview", limit: 255
      t.integer  "start_x_percent",     limit: 4
      t.integer  "start_y_percent",     limit: 4
      t.integer  "width_percent",       limit: 4
      t.integer  "height_percent",      limit: 4
      t.string   "custom_text",         limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "quantity_accepted",   limit: 4,                            default: 0, null: false
      t.integer  "quantity_received",   limit: 4,                            default: 0, null: false
    end

    add_index "store_order_items", ["daily_deal_id"], name: "index_store_order_items_on_daily_deal_id", using: :btree
    add_index "store_order_items", ["order_id"], name: "index_order_items_on_order_id", using: :btree
    add_index "store_order_items", ["product_id"], name: "index_order_items_on_product_id", using: :btree

    create_table "store_orders", force: :cascade do |t|
      t.integer  "domain_id",              limit: 4,                                              null: false
      t.string   "external_order_id",      limit: 255
      t.string   "sales_channel",          limit: 255
      t.integer  "user_id",                limit: 4
      t.string   "cart_key",               limit: 255,                            default: "",    null: false
      t.integer  "affiliate_campaign_id",  limit: 4
      t.integer  "referred_by",            limit: 4
      t.integer  "coupon_id",              limit: 4
      t.integer  "voucher_id",             limit: 4
      t.boolean  "combined",                                                      default: false, null: false
      t.boolean  "gift",                                                          default: false, null: false
      t.boolean  "auto_ship",                                                     default: false, null: false
      t.decimal  "tax_amount",                           precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "tax_rate",                             precision: 5,  scale: 2, default: 0.0,   null: false
      t.decimal  "shipping_cost",                        precision: 6,  scale: 2, default: 0.0,   null: false
      t.string   "shipping_method",        limit: 255
      t.decimal  "discount_amount",                      precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "credit_applied",                       precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "subtotal",                             precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "total",                                precision: 10, scale: 2, default: 0.0,   null: false
      t.string   "status",                 limit: 255,                                            null: false
      t.datetime "submitted"
      t.string   "shipping_name",          limit: 255
      t.string   "shipping_company",       limit: 255
      t.string   "shipping_street1",       limit: 255
      t.string   "shipping_street2",       limit: 255
      t.string   "shipping_city",          limit: 255
      t.string   "shipping_state",         limit: 255
      t.string   "shipping_zip",           limit: 255
      t.string   "shipping_country",       limit: 255
      t.string   "billing_name",           limit: 255
      t.string   "billing_company",        limit: 255
      t.string   "billing_street1",        limit: 255
      t.string   "billing_street2",        limit: 255
      t.string   "billing_city",           limit: 255
      t.string   "billing_state",          limit: 255
      t.string   "billing_zip",            limit: 255
      t.string   "billing_country",        limit: 255
      t.text     "customer_note",          limit: 65535
      t.string   "notify_email",           limit: 255
      t.string   "contact_phone",          limit: 255
      t.date     "payment_due"
      t.string   "payment_method",         limit: 255,                            default: ""
      t.boolean  "po",                                                            default: false, null: false
      t.boolean  "allow_backorder",                                               default: false, null: false
      t.date     "ship_earliest"
      t.date     "ship_latest"
      t.string   "cc_type",                limit: 255
      t.string   "cc_number",              limit: 255
      t.string   "cc_code",                limit: 255
      t.integer  "cc_expiration_month",    limit: 4
      t.integer  "cc_expiration_year",     limit: 4
      t.string   "paypal_token",           limit: 255
      t.string   "paypal_payer_id",        limit: 255
      t.decimal  "fb_discount",                          precision: 5,  scale: 2, default: 0.0,   null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "affiliate_id",           limit: 4
      t.date     "expected_delivery_date"
    end

    add_index "store_orders", ["coupon_id"], name: "index_orders_on_coupon_id", using: :btree
    add_index "store_orders", ["user_id"], name: "index_orders_on_user_id", using: :btree
    add_index "store_orders", ["voucher_id"], name: "index_orders_on_voucher_id", using: :btree

    create_table "store_product_categories", force: :cascade do |t|
      t.integer "product_id",  limit: 4, null: false
      t.integer "category_id", limit: 4, null: false
    end

    add_index "store_product_categories", ["category_id"], name: "index_product_categories_on_category_id", using: :btree
    add_index "store_product_categories", ["product_id"], name: "index_product_categories_on_product_id", using: :btree

    create_table "store_products", force: :cascade do |t|
      t.string   "name",                 limit: 255,                                            null: false
      t.string   "group",                limit: 255
      t.string   "product_type",         limit: 255
      t.string   "slug",                 limit: 255
      t.integer  "brand_id",             limit: 4
      t.string   "item_number",          limit: 255,                            default: "",    null: false
      t.string   "upc",                  limit: 255
      t.string   "sku",                  limit: 255
      t.boolean  "active",                                                      default: true,  null: false
      t.string   "title",                limit: 255
      t.string   "option_title",         limit: 255
      t.integer  "option_sort",          limit: 4
      t.decimal  "retail_map",                         precision: 10, scale: 2
      t.decimal  "price",                              precision: 10, scale: 2
      t.decimal  "msrp",                               precision: 10, scale: 2
      t.decimal  "special_price",                      precision: 10, scale: 2
      t.boolean  "free_shipping",                                               default: false, null: false
      t.boolean  "tax_exempt",                                                  default: false, null: false
      t.boolean  "hidden",                                                      default: false, null: false
      t.boolean  "featured",                                                    default: false, null: false
      t.boolean  "auto_ship",                                                   default: false, null: false
      t.boolean  "affiliate_only"
      t.boolean  "require_image_upload",                                        default: false, null: false
      t.text     "short_description",    limit: 65535
      t.text     "long_description",     limit: 65535
      t.string   "keywords",             limit: 255
      t.string   "warranty",             limit: 255
      t.integer  "fulfiller_id",         limit: 4
      t.integer  "label_sheet_id",       limit: 4
      t.decimal  "item_length",                        precision: 10, scale: 3
      t.decimal  "item_width",                         precision: 10, scale: 3
      t.decimal  "item_height",                        precision: 10, scale: 3
      t.decimal  "item_weight",                        precision: 10, scale: 3
      t.decimal  "case_length",                        precision: 10, scale: 3
      t.decimal  "case_width",                         precision: 10, scale: 3
      t.decimal  "case_height",                        precision: 10, scale: 3
      t.decimal  "case_weight",                        precision: 10, scale: 3
      t.integer  "case_quantity",        limit: 4
      t.string   "country_of_origin",    limit: 255
      t.integer  "low_threshold",        limit: 4
      t.date     "item_availability"
      t.string   "harmonized_code",      limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_products", ["brand_id"], name: "index_products_on_brand_id", using: :btree
    add_index "store_products", ["label_sheet_id"], name: "index_store_products_on_label_sheet_id", using: :btree

    create_table "store_shipment_items", force: :cascade do |t|
      t.integer  "shipment_id",    limit: 4,                null: false
      t.integer  "order_item_id",  limit: 4,                null: false
      t.integer  "product_id",     limit: 4,                null: false
      t.integer  "affiliate_id",   limit: 4
      t.string   "variation",      limit: 255
      t.integer  "quantity",       limit: 4,                null: false
      t.string   "special_status", limit: 64,  default: ""
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_shipment_items", ["order_item_id"], name: "index_shipment_items_on_product_id", using: :btree
    add_index "store_shipment_items", ["shipment_id"], name: "index_shipment_items_on_shipment_id", using: :btree

    create_table "store_shipments", force: :cascade do |t|
      t.integer  "order_id",             limit: 4
      t.integer  "sequence",             limit: 4,                                                 null: false
      t.integer  "fulfilled_by_id",      limit: 4
      t.decimal  "invoice_amount",                        precision: 10, scale: 2, default: 0.0,   null: false
      t.string   "status",               limit: 255,                                               null: false
      t.string   "ship_from_company",    limit: 255,                               default: "",    null: false
      t.string   "ship_from_street1",    limit: 255,                               default: "",    null: false
      t.string   "ship_from_street2",    limit: 255
      t.string   "ship_from_city",       limit: 255,                               default: "",    null: false
      t.string   "ship_from_state",      limit: 255,                               default: "",    null: false
      t.string   "ship_from_zip",        limit: 255,                               default: "",    null: false
      t.string   "ship_from_country",    limit: 255,                               default: "",    null: false
      t.string   "ship_from_email",      limit: 255
      t.string   "ship_from_phone",      limit: 255
      t.string   "recipient_name",       limit: 255,                                               null: false
      t.string   "recipient_company",    limit: 255
      t.string   "recipient_street1",    limit: 255,                                               null: false
      t.string   "recipient_street2",    limit: 255
      t.string   "recipient_city",       limit: 255,                                               null: false
      t.string   "recipient_state",      limit: 255
      t.string   "recipient_zip",        limit: 255,                                               null: false
      t.string   "recipient_country",    limit: 255,                                               null: false
      t.string   "carrier",              limit: 255
      t.string   "ship_method",          limit: 255
      t.string   "tracking_number",      limit: 255
      t.date     "ship_date"
      t.decimal  "ship_cost",                             precision: 6,  scale: 2
      t.decimal  "package_length",                        precision: 6,  scale: 2
      t.decimal  "package_width",                         precision: 6,  scale: 2
      t.decimal  "package_height",                        precision: 6,  scale: 2
      t.decimal  "package_weight",                        precision: 6,  scale: 2
      t.text     "notes",                limit: 65535
      t.string   "packaging_type",       limit: 255
      t.boolean  "require_signature"
      t.decimal  "insurance",                             precision: 8,  scale: 2, default: 0.0,   null: false
      t.string   "drop_off_type",        limit: 255
      t.binary   "label_data",           limit: 16777215
      t.string   "label_format",         limit: 255
      t.string   "courier_name",         limit: 255
      t.text     "courier_data",         limit: 16777215
      t.boolean  "fulfiller_notified",                                             default: false, null: false
      t.boolean  "inventory_updated",                                              default: false, null: false
      t.string   "batch_status",         limit: 255
      t.string   "batch_status_message", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "manifest_id",          limit: 4
      t.boolean  "third_party_billing",                                            default: false, null: false
    end

    add_index "store_shipments", ["order_id"], name: "index_shipments_on_order_id", using: :btree

    create_table "store_shipping_options", force: :cascade do |t|
      t.integer  "domain_id",               limit: 4,                              null: false
      t.string   "name",                    limit: 255,                            null: false
      t.decimal  "base_cost",                             precision: 10, scale: 2, null: false
      t.decimal  "min_order_amount",                      precision: 10, scale: 2
      t.decimal  "max_order_amount",                      precision: 10, scale: 2
      t.boolean  "active",                                                         null: false
      t.string   "add_product_attribute",   limit: 255
      t.boolean  "international_surcharge",                                        null: false
      t.text     "description",             limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_tax_rates", force: :cascade do |t|
      t.string   "code",             limit: 255,                         null: false
      t.string   "country_code",     limit: 255,                         null: false
      t.string   "state_code",       limit: 255,                         null: false
      t.string   "city",             limit: 255,                         null: false
      t.string   "county",           limit: 255,                         null: false
      t.decimal  "rate",                         precision: 5, scale: 2, null: false
      t.boolean  "shipping_taxable",                                     null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_upc", force: :cascade do |t|
      t.string   "code",        limit: 255
      t.string   "item",        limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "notes",       limit: 255, default: "", null: false
      t.string   "flags",       limit: 255
      t.string   "image_label", limit: 255
    end

    create_table "store_user_voucher_histories", force: :cascade do |t|
      t.integer  "user_id",    limit: 4,                            null: false
      t.integer  "voucher_id", limit: 4
      t.decimal  "amount",                 precision: 10, scale: 2, null: false
      t.integer  "order_id",   limit: 4
      t.string   "notes",      limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_user_voucher_histories", ["order_id"], name: "index_user_voucher_histories_on_order_id", using: :btree
    add_index "store_user_voucher_histories", ["user_id"], name: "index_user_voucher_histories_on_user_id", using: :btree
    add_index "store_user_voucher_histories", ["voucher_id"], name: "index_user_voucher_histories_on_voucher_id", using: :btree

    create_table "store_voucher_groups", force: :cascade do |t|
      t.string   "name",       limit: 255,                          null: false
      t.decimal  "value",                  precision: 10, scale: 2, null: false
      t.datetime "expires",                                         null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_vouchers", force: :cascade do |t|
      t.integer  "voucher_group_id", limit: 4,                                          null: false
      t.string   "code",             limit: 255,                                        null: false
      t.boolean  "issued"
      t.decimal  "amount_used",                  precision: 10, scale: 2, default: 0.0, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_vouchers", ["voucher_group_id"], name: "index_vouchers_on_voucher_group_id", using: :btree

    create_table "store_zip_codes", force: :cascade do |t|
      t.string  "code",             limit: 16,                          default: "",    null: false
      t.string  "country_code",     limit: 2,                           default: "",    null: false
      t.string  "state_code",       limit: 2,                           default: "",    null: false
      t.string  "city",             limit: 32,                          default: "",    null: false
      t.string  "county",           limit: 32,                          default: "",    null: false
      t.decimal "latitude",                    precision: 10, scale: 7
      t.decimal "longitude",                   precision: 10, scale: 7
      t.decimal "tax_rate",                    precision: 6,  scale: 2,                 null: false
      t.boolean "shipping_taxable",                                     default: false, null: false
    end
    
    create_table "inv_items", force: :cascade do |t|
      t.integer  "inventory_transaction_id", limit: 4,                           null: false
      t.string   "sku",                      limit: 255,                         null: false
      t.integer  "inventory_location_id",    limit: 4,                           null: false
      t.integer  "quantity",                 limit: 4,                           null: false
      t.string   "lot",                      limit: 255
      t.integer  "expiration",               limit: 4
      t.decimal  "cost",                                 precision: 8, scale: 2
      t.datetime "created_at",                                                   null: false
      t.datetime "updated_at",                                                   null: false
    end

    create_table "inv_locations", force: :cascade do |t|
      t.string   "name",         limit: 255,   default: "",    null: false
      t.integer  "depth",        limit: 4
      t.integer  "height",       limit: 4
      t.integer  "width",        limit: 4
      t.boolean  "large_box",                  default: false, null: false
      t.boolean  "heavy_box",                  default: false, null: false
      t.boolean  "holding_area",               default: false, null: false
      t.boolean  "usable",                     default: true,  null: false
      t.text     "notes",        limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "inv_transactions", force: :cascade do |t|
      t.integer  "user_id",           limit: 4
      t.integer  "shipment_id",       limit: 4
      t.integer  "purchase_order_id", limit: 4
      t.text     "notes",             limit: 65535
      t.datetime "created_at",                      null: false
      t.datetime "updated_at",                      null: false
    end
    
    create_table "inv_purchase_order_items", force: :cascade do |t|
      t.integer  "purchase_order_id", limit: 4,                                          null: false
      t.string   "sku",               limit: 32,                           default: "",  null: false
      t.integer  "quantity",          limit: 4,                            default: 1,   null: false
      t.string   "description",       limit: 255
      t.string   "supplier_code",     limit: 255
      t.string   "upc",               limit: 255
      t.decimal  "unit_price",                    precision: 12, scale: 4, default: 0.0, null: false
      t.decimal  "discount",                      precision: 10, scale: 2
      t.integer  "quantity_received", limit: 4,                            default: 0,   null: false
      t.string   "status",            limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "inv_purchase_order_items", ["sku"], name: "index_purchase_order_items_on_sku_id", using: :btree

    create_table "inv_purchase_orders", force: :cascade do |t|
      t.integer  "affiliate_id",  limit: 4
      t.integer  "supplier_id",   limit: 4
      t.string   "status",        limit: 255
      t.date     "issue_date"
      t.date     "due_date"
      t.string   "ship_method",   limit: 255
      t.string   "payment_terms", limit: 255
      t.string   "ship_to",       limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "notes",         limit: 65535
    end

    add_index "inv_purchase_orders", ["affiliate_id"], name: "index_store_purchase_orders_on_affiliate_id", using: :btree
  
  end
end

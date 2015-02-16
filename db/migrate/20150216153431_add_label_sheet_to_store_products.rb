class AddLabelSheetToStoreProducts < ActiveRecord::Migration
  def change
    add_reference :store_products, :label_sheet, index: true
  end
end

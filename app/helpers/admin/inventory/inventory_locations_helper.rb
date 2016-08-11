module Admin::Inventory::InventoryLocationsHelper
  
  def inventory_location_dimensions(loc)
    if loc.depth && loc.width && loc.height
      "#{loc.depth}&quot; &times; #{loc.width}&quot; &times; #{loc.height}&quot;".html_safe
    else
      "<span class='light'>n/a</span>".html_safe
    end
  end
  
end
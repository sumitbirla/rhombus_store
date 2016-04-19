module AutoShipHelper
  
  def auto_ship_status(asi)
    
    css = "label-danger"
    
    if asi.status == 'active'
      css = 'label-success'
    end

    "<span class='label #{css}'>#{asi.status}</span>".html_safe
  end
  
end
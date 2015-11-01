module AutoShipHelper
  
  def auto_ship_status(asi)
    
    css = "label-info"
    
    if asi.status == 'active'
      css = 'label-success'
    elsif asi.status == 'billing_failed'
      css = 'label-danger'
    end

    "<span class='label #{css}'>#{asi.status}</span>".html_safe
  end
  
end
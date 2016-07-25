class EasypostController < ApplicationController
  
  def webhook
    Rails.logger.info "EASYPOST WEBHOOK TRIGGERED"
    Rails.logger.info params[:result].inspect
    
    render :nothing => true, :status => 200
  end
  
end

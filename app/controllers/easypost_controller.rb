class EasypostController < ApplicationController

  def webhook
    Rails.logger.info "EASYPOST WEBHOOK TRIGGERED"
    Rails.logger.info params[:result].inspect

    begin
      result = params["result"]

      case result["object"]
      when "ScanForm"
        if result["status"] == "created"
          m = Manifest.find_by(batch_id: result["batch_id"])
          m.update(document_url: result["form_url"]) unless m.nil?
        end
      end
    rescue => e
      Rails.logger.error e
    end

    head :ok
  end

end

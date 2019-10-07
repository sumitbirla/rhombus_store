require 'easypost'

class Admin::Store::ManifestsController < Admin::BaseController
  
  def index
    authorize Manifest.new
    
    aff_id = Setting.get(Rails.configuration.domain_id, :shipping, "Affiliate ID")
    
    sql = <<-EOF
      select carrier, count(*)
      from store_shipments
      where fulfilled_by_id = #{aff_id}
      and status = 'shipped'
      and ship_date = '#{Date.today}'
      and manifest_id IS NULL
      and carrier <> ''
      group by carrier;
    EOF

    @manifests = []
    ActiveRecord::Base.connection.execute(sql).each do |row|
      @manifests << Manifest.new(carrier: row[0], shipment_count: row[1], day: Date.today, status: :open)
    end

    @recent_manifests = Manifest.where("day > ?", 1.week.ago).order(created_at: :desc)
  end
  
  def create
    manifest = authorize Manifest.new(manifest_params)
    aff_id = Setting.get(Rails.configuration.domain_id, :shipping, "Affiliate ID")
    
    # EasyPost.api_key = Cache.setting(Rails.configuration.domain_id, :shipping, 'EasyPost API Key')
    EasyPost.api_key = "EZAKf450411cc98a4a6eac6f7671d89a0b0cjOAdPcyWzaTCJoSIfcz8mg"
    shipments = Shipment.where(fulfilled_by_id: aff_id, ship_date: manifest.day, carrier: manifest.carrier, status: :shipped, manifest_id: nil)
    
    data = []
    shipment_ids = []
    
    begin
      shipments.each do |s|
        next if s.courier_data.blank?
        
        data << { id: JSON.parse(s.courier_data)["id"] }
        shipment_ids << s.id
      end
      
      batch = EasyPost::Batch.create(shipments: data)
      batch.create_scan_form()
      manifest.batch_id = batch.id
      manifest.shipment_count = shipments.length
      manifest.status = :closed
      manifest.save!
      
      # update shipments
      Shipment.where(id: shipment_ids).update_all(manifest_id: manifest.id)
    rescue => e
      Rails.logger.error e
      flash[:error] = e.message
    end
    
    redirect_back(fallback_location: admin_root_path)
  end
  
  def request_pickup
    
  end
  
  
  private
  
    def manifest_params
      params.require(:manifest).permit!
    end
  
end

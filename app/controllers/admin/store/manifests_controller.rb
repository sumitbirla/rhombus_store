require 'easypost'

class Admin::Store::ManifestsController < Admin::BaseController
  
  def index
    sql = <<-EOF
      select carrier, count(*)
      from store_shipments
      where status = 'shipped'
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
    manifest = Manifest.new(manifest_params)
    EasyPost.api_key = Cache.setting(Rails.configuration.domain_id, :shipping, 'EasyPost API Key')
    shipments = Shipment.where(ship_date: manifest.day, carrier: manifest.carrier, status: :shipped, manifest_id: nil)
    
    data = []
    shipment_ids = []
    
    begin
      shipments.each do |s|
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
      flash[:error] = e.message
    end
    
    redirect_to :back
  end
  
  def request_pickup
    
  end
  
  
  private
  
    def manifest_params
      params.require(:manifest).permit!
    end
  
end

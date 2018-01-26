class AmazonPersonalizationJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    
    o = Order.find(order_id)
    
    o.items.each do |i|
      next if i.uploaded_file.blank?
      tmp_dir = "/tmp/" + SecureRandom.hex(6)
      Dir.mkdir(tmp_dir)
      system("wget #{i.uploaded_file} -O #{tmp_dir}/files.zip")
      system("unzip #{tmp_dir}/files.zip -d #{tmp_dir}")
    end
    
  end
end

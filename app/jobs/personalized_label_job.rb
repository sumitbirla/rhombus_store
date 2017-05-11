require 'rmagick'
require 'net/scp'
require 'uri'

class PersonalizedLabelJob < ActiveJob::Base
  queue_as :image_processing

  def perform(order_item_id, medium)
    static_files_path = Setting.get('System', 'Static Files Path')
    
    i = OrderItem.find(order_item_id)
    p = i.product
    
    bg_image_path = static_files_path + p.pictures.find { |x| x.purpose == "#{medium}_background" }.file_path
    elem = p.label_elements.find { |x| x.text_or_image == 'image' && x.web_or_print == medium }
    
    # read the product image with space for dog photo
    bg = Magick::Image::read(bg_image_path)[0]
    Rails.logger.debug "Background image is #{bg.columns}x#{bg.rows} pixels"

    # read dog photo
    dog = Magick::Image::read(static_files_path + i.uploaded_file)[0]
    Rails.logger.debug "Uploaded image is #{dog.columns}x#{dog.rows} pixels"

    Rails.logger.debug  "TARGET -> #{elem.width} x #{elem.height} starting at (#{elem.left} x #{elem.top})"

    # create backfill for dog area
    back_fill = Magick::GradientFill.new(0, 0, 0, 0, "#ffffff", "#ffffff")

    # resize dog per user upload
    resized_dog = dog.resize(elem.width * i.width_percent / 100.0, elem.height * i.height_percent / 100.0)

    # draw the dog on the backfill area
    buffer = Magick::Image.new(elem.width, elem.height, back_fill)
    buffer = buffer.composite(resized_dog, Magick::ForgetGravity, elem.width * i.start_x_percent / 100.0, elem.height * i.start_y_percent / 100.0, Magick::OverCompositeOp)

    # copy backfill (with dog on it) to the main product image
    output_file = "/personalized_labels/" + SecureRandom.hex(6) + ".jpg"
    final = bg.composite(buffer, elem.left, elem.top, Magick::OverCompositeOp)
    final.write(static_files_path + output_file) { self.quality = 100 }
    
    Rails.logger.debug "PREVIEW image writtem to #{static_files_path + output_file}"
    
    if medium == 'print'
      i.update(rendered_file: output_file)
      
      # COPY label to Kiaro printer PC
      begin
        uri = URI(Setting.get(:kiaro, "Personalized Labels Destination"))
        Net::SCP.upload!(uri.host, uri.user, output_file, uri.path, :ssh => { :password => uri.password, :port => uri.port || 22 })
        Rails.logger.info "Copied #{output_file} to destination"
      rescue => e
        Rails.logger.error e.message
      end
      
    else
      i.update(upload_file_preview: output_file)
    end
    
  end
end

require 'rmagick'
require 'net/scp'
require 'uri'

class PersonalizedLabelJob < ActiveJob::Base
  queue_as :image_processing
  
  
  def draw_text(elem, bg, text)
    text_img = Magick::Image.new(elem.width, elem.height)
    draw = Magick::Draw.new
    draw.annotate(text_img, 0, 0, 0, 0, text) do
      draw.gravity = Magick::CenterGravity
      self.pointsize = elem.font_size || 38
      self.font_family = elem.font_family || "Arial"
      self.font_weight = Magick::NormalWeight
      self.stroke = "none"
      self.fill = elem.font_color || "#000000"
    end

    bg.composite!(text_img, elem.left, elem.top, Magick::OverCompositeOp)
  end
  
  
  def draw_image(elem, bg, order_item)
    i = order_item
    img = Magick::Image::read(static_files_path + i.uploaded_file)[0]
    #img = Magick::Image::read("./1.jpg")[0]
    
    # create backfill for dog area
    back_fill = Magick::GradientFill.new(0, 0, 0, 0, "#ffffff", "#ffffff")

    # resize dog per user upload
    resized_img = img.resize(elem.width * i.width_percent / 100.0, elem.height * i.height_percent / 100.0)

    # draw the dog on the backfill area
    buffer = Magick::Image.new(elem.width, elem.height, back_fill)
    buffer = buffer.composite(resized_img, Magick::ForgetGravity, elem.width * i.start_x_percent / 100.0, elem.height * i.start_y_percent / 100.0, Magick::OverCompositeOp)
    bg.composite!(buffer, elem.left, elem.top, Magick::OverCompositeOp)
  end
  

  def perform(order_item_id, medium)
    static_files_path = Setting.get('System', 'Static Files Path')
      
    i = OrderItem.find(order_item_id)
    p = i.product
    
    # read the product image with space for photo and/or text
    bg_image_path = static_files_path + p.pictures.find { |x| x.purpose == "#{medium}_background" }.file_path
    bg = Magick::Image::read(bg_image_path)[0]
    #bg = Magick::Image::read("./SCT-PK100.jpg")[0]
    Rails.logger.debug "Background image is #{bg.columns}x#{bg.rows} pixels"

    # render the text or image elements
    p.label_elements.select { |x| x.web_or_print == medium }.each do |elem|
      if elem.text_or_image == 'image'
        draw_image(elem, bg, i)
      elsif
        draw_text(elem, bg, "OID: #{i.order_id}")
      end
    end

    output_file = "/personalized_labels/" + SecureRandom.hex(6) + ".jpg"
    bg.write(static_files_path + output_file) { self.quality = 100 }
    #bg.write("./output.jpg") { self.quality = 100 }
    
    Rails.logger.debug "PREVIEW image written to #{static_files_path + output_file}"
    
    if medium == 'print'
      i.update(rendered_file: output_file)
      
      # COPY label to Kiaro printer PC
      begin
        uri = URI(Setting.get(:kiaro, "Personalized Labels Destination"))
        Net::SCP.upload!(uri.host, uri.user, static_files_path + output_file, uri.path, :ssh => { :password => uri.password, :port => uri.port || 22 })
        Rails.logger.info "Copied #{static_files_path + output_file} to destination"
      rescue => e
        Rails.logger.error e.message
      end
      
    else
      i.update(upload_file_preview: output_file)
    end
    
  end
end

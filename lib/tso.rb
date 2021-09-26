require 'rest-client'
require 'json'
require './lib/vci_slide.rb'

class Tso
  def initialize(token)
    @url = "https://api.seed.online"
    @token = token
  end

  def call_api(path, data, url=@url)
    begin
      ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36"
      headers = { 
          'Accept' => 'application/json',
          'Authorization'=> @token,
          'User-Agent' => ua
      }
  
      req = RestClient::Request.new(
        :method => :post,
        :url => url + path,
        :headers => headers,
        :payload => data
      )
      res = req.execute
  
      return res
    rescue => e
        puts "Error: #{e}"
        return nil
    end
  end

  def upload_icon item_id, src_blob
    require 'rmagick'

    height = 512
    width = 512
    thum_path = "/tmp/thum.png"

    image = Magick::Image.from_blob(src_blob).first
    narrow = image.columns > image.rows ? image.rows : image.columns

    thum = image.crop(Magick::CenterGravity, narrow, narrow).resize(width, height)
    thum.write(thum_path)

    response = call_api("/files/user/post-items/#{item_id}/icon", {
      :file => open(thum_path)
    })
    r = [JSON.load(response.body), thum_path]
  end

  def add_prodcut(item_id, title, description, thum_path)
    response = call_api("/products", {
      :itemId => item_id,
      :title => title,
      :description => description,
      :accessibility => 'protected',
      :salesMethod => 'outright_purchase',
      :price => 0,
      :isSoldOnWeb => 1,
      :isSoldOnVr => 1,
      'thumbnails[0]' => open(thum_path),
      'newOrder[0]'=> thum_path.split('/').last
    })
    # }, "http://127.0.0.1:4567")

    p response
    r = JSON.load(response.body)
  end

  def upload_vci(file)
    # upload vci
    vci_data = file.read  # load for icon
    file.pos = 0          # reset file position
    # file_data = open('/home/koduki/pictures/20210912.png').read
    response = call_api("/files/user/post-items", {
      :itemType => 'prop',
      :file => file
    })
    r = JSON.load(response.body)

    # parse VCI
    require 'stringio'
    io = StringIO.new(vci_data)

    vci_slide = VCISlide.new
    property, glb_buff_data = vci_slide.load_template_from_data(io)

    vci_meta = property["extensions"]["VCAST_vci_meta"]
    title = vci_meta["title"]
    desc = vci_meta["description"]
    thum_idx = vci_meta["thumbnail"]

    # update icon
    img_idx = property["images"][thum_idx]["bufferView"]
    img_len = property["bufferViews"][img_idx]["byteLength"]

    bfv = property["bufferViews"][img_idx]
    img_data = glb_buff_data[bfv["byteOffset"], bfv["byteLength"]]
    icon_data = img_data.unpack('C*').pack('C*')
    
    item_id = r['itemId']
    r_icon = upload_icon item_id, icon_data

    # add to prodcut
    r_prdct = add_prodcut item_id, title, desc, r_icon[1]
    [r, r_icon, r_prdct]
  end

  def upload_pic(file, title, author)
    # upload image
    icon_data = file.read # load for icon
    file.pos = 0          # reset file position
    response = call_api("/files/user/post-items/image", {
      :title => title,
      :author => author,
      :version => '',
      :file => file
    })

    # update icon
    
    r = JSON.load response.body
    item_id = r['itemId']
    r_icon = upload_icon item_id, icon_data

    # add to prodcut
    r_prdct = add_prodcut item_id, title, 'Photo in VirtualCast', r_icon[1]

    [r, r_icon, r_prdct]
  end

end
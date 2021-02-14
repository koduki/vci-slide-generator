require 'json'

template_vci_path = ARGV[0] #'WhiteBoard.vci'
image_path = ARGV[1]  #'001.png'
page_size = ARGV[2].to_f
output_path = ARGV[3] #'dist/output.vci'
info = {title:ARGV[4], version:ARGV[5], author:ARGV[6], description:ARGV[7]}

GLB_H_SIZE = 4
GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

#
# Load Template
#
io = open(template_vci_path)
glb_h_magic = io.read(GLB_H_SIZE)
glb_h_version = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_h_length = io.read(GLB_H_SIZE).unpack("L*")[0]

glb_json_length = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_json_type = io.read(GLB_H_SIZE)
glb_json_data = io.read(glb_json_length)

glb_buff_length = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_buff_type = io.read(GLB_H_SIZE)
glb_buff_data = io.read(glb_buff_length)

property = JSON.parse(glb_json_data)

#
# Prepare resources
#

# load image
image = open(image_path, 'rb').read
img_idx = property["images"].find{|x| x["name"] == "template" }["bufferView"]

# Lua Script
src = <<"EOS"
GrabCount = 0
UseCount = 0
MAX_SLIDE_PAGE = #{page_size.to_i}

function onGrab(target)
    GrabCount = GrabCount + 1
    print("Grab : "..GrabCount)
    print(target)
end

function onUse(use)
    UseCount = UseCount + 1
    print("onUse : "..use..UseCount)

    local index = UseCount % MAX_SLIDE_PAGE
    local offset = Vector2.zero
    offset.y = 0
    offset.x = (1.0 / MAX_SLIDE_PAGE) * index
    vci.assets._ALL_SetMaterialTextureOffsetFromName("ScreenTexture", offset)
    print("page: "..(index + 1))
end
EOS
src_idx = property["extensions"]["VCAST_vci_embedded_script"]["scripts"][0]["source"]

#
# Create Data
#

def padding_size(data_size)
    if data_size == 0 then
        return 0
    else
        m = data_size % 4
        return m > 0 ? 4 - m : 0
    end
end

data = ""
property["bufferViews"].each_with_index do |x, i|
    case i
    when img_idx
        data += image + FF * padding_size(image.size)
    when src_idx
        data += src + FF * padding_size(src.size)
    else
        data += glb_buff_data[x["byteOffset"], x["byteLength"]]
    end
end

#
# Create JSON
#

# Update meta data
vci_meta = property["extensions"]["VCAST_vci_meta"]
vci_meta["title"] = info[:title]
vci_meta["version"] = info[:version]
vci_meta["author"] = info[:author]
vci_meta["description"] = info[:description]

# Adjust for page size
material = property["materials"].find{|x| x["name"] == "ScreenTexture"}
material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / page_size).floor(5), 1]

# buffers/Update bufferViews
property["bufferViews"][src_idx]["byteLength"] = src.size
property["bufferViews"][img_idx]["byteLength"] = image.size
xs = property["bufferViews"]
(1..xs.size-1).each do |i|
    px = xs[i - 1]
    offset = px["byteOffset"] + px["byteLength"]
    offset += padding_size(src.size) if i==(src_idx + 1)
    offset += padding_size(image.size) if i==(img_idx + 1)
    xs[i]["byteOffset"] = offset
end

property["buffers"][0]["byteLength"] = data.size
json = property.to_json.gsub('/', '\/')

# Padding　for 4 byte boundary
p "json-size: #{json.size}"
json_padding = padding_size(json.size)

json = json + (" " * json_padding)
p "padding: #{json_padding}, json-size: #{json.size}"

p "image-size: #{image.size}"
p "data-size: #{data.size}"
data_padding = padding_size(data.size)
data = data + (FF * data_padding)
p "padding: #{data_padding}, data-size: #{data.size}"


# p "(json) % 2 == #{(data.size) % 2}"
# p "(json) % 3 == #{(data.size) % 3}"
# p "(json) % 4 == #{(data.size) % 4}"
# p "(json + data) % 2 == #{(json.size + data.size) % 2}"
# p "(json + data) % 3 == #{(json.size + data.size) % 3}"
# p "(json + data) % 4 == #{(json.size + data.size) % 4}"



#
# Store as GLB
#
glb = GLB_H_MAGIC
glb += GLB_H_VERSION
glb += [(GLB_H_SIZE * 3) + (GLB_H_SIZE * 2) + json.size + (GLB_H_SIZE * 2) + data.size].pack("L*")

glb += [json.size].pack("L*")
glb += GLB_JSON_TYPE
glb += json

glb += [data.size].pack("L*")
glb += GLB_BUFF_TYPE
glb += data

open(output_path, 'wb') do |f|
    f.write(glb)
end
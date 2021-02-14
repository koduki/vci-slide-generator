require 'json'

template_vci_path = ARGV[0] #'WhiteBoard.vci'
image_path = ARGV[1]  #'001.png'
output_path = ARGV[2] #'output.vci'
info = {title:ARGV[3], version:ARGV[4], author:ARGV[5], description:ARGV[6]}
page_size = ARGV[7].to_f

GLB_H_SIZE = 4
GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

# Load Template
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

# Update meta
vci_meta = property["extensions"]["VCAST_vci_meta"]
vci_meta["title"] = info[:title]
vci_meta["version"] = info[:version]
vci_meta["author"] = info[:author]
vci_meta["description"] = info[:description]

# Adjust for page size
material = property["materials"].find{|x| x["name"] == "ScreenTexture"}
material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / page_size).floor(5), 1]

#
# Create Data
#

# load image
img_idx = 0
image = open(image_path, 'rb').read

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
property["bufferViews"][src_idx]["byteLength"] = src.size


diff = (4 - (image.size % 3)) # zero padding
# diff = 0
data = image + FF * diff
property["bufferViews"].each_with_index do |x, i|
    next if i==img_idx
    if i == src_idx
        data += src
        next
    end
    data += glb_buff_data[x["byteOffset"], x["byteLength"]]
end

# Create JSON
property["images"][0]["name"]="MySlide"
property["bufferViews"][0]["byteLength"] = image.size
xs = property["bufferViews"]
(1..xs.size-1).each do |i|
    px = xs[i - 1]
    offset = px["byteOffset"] + px["byteLength"]
    offset += diff if i==(img_idx + 1)
    xs[i]["byteOffset"] = offset
end
property["buffers"][0]["byteLength"] = data.size
json = property.to_json.gsub('/', '\/')

# Padding
p "image-size: #{image.size}"
p "json-size: #{json.size}"
# diff = 4 - (json.size % 4)
# diff += 1 if data.size % 2 == 0 # なぜ必要かが分からないけどこれで補正すると動く 
# diff2 = 1#(json.size + data.size) % 4 
# p "diff2=#{diff2}"
# diff = (4 - (json.size % 4)) + diff2

paddingValue = json.size % 4
padding = (paddingValue > 0) ? 4 - paddingValue : 0;
padding += 3
p "padding: #{padding}"
json = json + (" " * padding) # space padding for 4 byte boundary
p json.size

p "data-size: #{data.size}"
# diff = 4 - (data.size % 4)
paddingValue = data.size % 4
padding = (paddingValue > 0) ? 4 - paddingValue : 0;
padding += 0
p "padding: #{padding}"
data = data + (FF * padding) # zero padding for 4 byte boundary
p data.size

p "(json) % 2 == #{(data.size) % 2}"
p "(json) % 3 == #{(data.size) % 3}"
p "(json) % 4 == #{(data.size) % 4}"
p "(json + data) % 2 == #{(json.size + data.size) % 2}"
p "(json + data) % 3 == #{(json.size + data.size) % 3}"
p "(json + data) % 4 == #{(json.size + data.size) % 4}"

# Store GLTF
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
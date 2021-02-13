require 'json'

template_vci_path = ARGV[0] #'WhiteBoard.vci'
image_path = ARGV[1]  #'testdata.png'
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
material = property["materials"].find{|x| x["name"] == "WB_Material"}
#material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / page_size).floor(5), 1]

# Create Data
image = open(image_path, 'rb').read

diff = (4 - (image.size % 3)) # zero padding
data = image + FF * diff
target_idx = 0
property["bufferViews"].each_with_index do |x, i|
    next if i==target_idx
    data += glb_buff_data[x["byteOffset"], x["byteLength"]]
end

# Create JSON
property["images"][0]["name"]="slide"
property["bufferViews"][0]["byteLength"] = image.size
xs = property["bufferViews"]
(1..xs.size-1).each do |i|
    px = xs[i - 1]
    offset = px["byteOffset"] + px["byteLength"]
    offset += diff if i==(target_idx + 1)
    xs[i]["byteOffset"] = offset
end
property["buffers"][0]["byteLength"] = data.size
json = property.to_json.gsub('/', '\/') + "   "

# Store GLTF
glb = GLB_H_MAGIC
glb += GLB_H_VERSION
glb += [json.size + data.size + (GLB_H_SIZE * 3) + (GLB_H_SIZE * 2) + (GLB_H_SIZE * 2)].pack("L*")

glb += [json.size].pack("L*")
glb += GLB_JSON_TYPE
glb += json

glb += [data.size].pack("L*")
glb += GLB_BUFF_TYPE
glb += data

open(output_path, 'wb') do |f|
    f.write(glb)
end
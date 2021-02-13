irb(main):036:0> image.size
=> 213393



dataLength = property["bufferViews"].map{|x|x["byteLength"]}.reduce(0){|r, x| r+x} + 12
property["buffers"][0]["byteLength"]=property["bufferViews"].map{|x|x["byteLength"]}.reduce(0){|r, x| r+x} + 12


GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

# Load Template
io = open('WhiteBoard.vci')
glb_h_magic = io.read(4)
glb_h_version = io.read(4).unpack("L*")[0]
glb_h_length = io.read(4).unpack("L*")[0]

glb_json_length = io.read(4).unpack("L*")[0]
glb_json_type = io.read(4)
glb_json_data = io.read(glb_json_length);1

glb_buff_length = io.read(4).unpack("L*")[0]
glb_buff_type = io.read(4)
glb_buff_data = io.read(glb_buff_length);1

property=JSON.parse(glb_json_data)


# Create Data
image = open('testdata.png', 'rb').read;1
data = image + FF + FF + FF;1
property["bufferViews"].each_with_index do |x, i|
    next if i==0 
    data += glb_buff_data[x["byteOffset"], x["byteLength"]];
    # data += FF*4 if i==2
    # data += FF*8 if i==4
end
data += FF;1

# Create JSON
property["images"][0]["name"]="testdata"
property["bufferViews"][0]["byteLength"] = image.size
xs = property["bufferViews"]
(1..xs.size-1).each do |i|
    x = xs[i - 1]
    offset = x["byteOffset"] + x["byteLength"]
    offset += 3 if i==1
    # offset += 4 if i==3
    # offset += 8 if i==5
    xs[i]["byteOffset"] = offset
end
property["buffers"][0]["byteLength"] = data.size
json = property.to_json.gsub('/', '\/') + "   "

# Store GLTF
glb = GLB_H_MAGIC
glb += GLB_H_VERSION
glb += [json.size + data.size + 12 + 8 + 8].pack("L*")

glb += [json.size].pack("L*")
glb += GLB_JSON_TYPE
glb += json

glb += [data.size].pack("L*")
glb += GLB_BUFF_TYPE
glb += data;1

open('output.vci', 'wb') do |f|
    f.write(glb)
end


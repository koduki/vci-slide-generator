require 'json'

input_path = ARGV[0] #'WhiteBoard.vci'
output = ARGV[1]

GLB_H_SIZE = 4
GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

# Load Template
io = open(input_path)
glb_h_magic = io.read(GLB_H_SIZE)
glb_h_version = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_h_length = io.read(GLB_H_SIZE).unpack("L*")[0]

glb_json_length = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_json_type = io.read(GLB_H_SIZE)
glb_json_data = io.read(glb_json_length)

glb_buff_length = io.read(GLB_H_SIZE).unpack("L*")[0]
glb_buff_type = io.read(GLB_H_SIZE)
glb_buff_data = io.read(glb_buff_length)


open("#{output}.json", "w").write(glb_json_data)
open("#{output}.data", "wb").write(glb_buff_data)
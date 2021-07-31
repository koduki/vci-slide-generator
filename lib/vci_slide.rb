require 'json'

GLB_H_SIZE = 4
GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

class VCISlide
    attr_accessor :template_vci_path, :vci_script_path, :image_path, :page_size, :output_path, :meta_title, :meta_version, :meta_author, :meta_description

    def initialize template_vci_path, vci_script_path, image_path, page_size, output_path
        @template_vci_path = template_vci_path
        @vci_script_path = vci_script_path
        @image_path = image_path
        @page_size = page_size
        @output_path = output_path
        @meta_title = "untitled"
        @meta_version = 1.0
        @meta_author = "unknown"
        @meta_description = "none"
    end

    def generate
        property, glb_buff_data = load_template(@template_vci_path)
        image, img_idx = load_image(property, @image_path)
        src, src_idx = load_script(property, page_size)

        data = mk_data(property, glb_buff_data, image, img_idx, src, src_idx)
        meta = {title:@meta_title, version:@meta_version, author:@meta_author, description:@meta_description}
        json = mk_json(property, image, img_idx, src, src_idx, data, @page_size, meta)

        json, data = align(json,  data)
        store(@output_path, json, data)
    end

    #
    # Store as GLB
    #
    def store output_path, json, data
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
    end

    def align json, data
        json_padding = padding_size(json.size)
        json = json + (" " * json_padding)
    
        data_padding = padding_size(data.size)
        data = data + (FF * data_padding)
    
        return [json, data]
    end

    def padding_size(data_size)
        if data_size == 0 then
            return 0
        else
            m = data_size % 4
            return m > 0 ? 4 - m : 0
        end
    end

    #
    # Load Template
    #
    def load_template template_vci_path
        io = open(template_vci_path)
        glb_h_magic = io.read(GLB_H_SIZE)
        glb_h_version = io.read(GLB_H_SIZE).unpack("L*")[0]
        glb_h_length = io.read(GLB_H_SIZE).unpack("L*")[0]

        glb_json_length = io.read(GLB_H_SIZE).unpack("L*")[0]
        glb_json_type = io.read(GLB_H_SIZE)
        glb_json_data = io.read(glb_json_length).force_encoding("utf-8")

        glb_buff_length = io.read(GLB_H_SIZE).unpack("L*")[0]
        glb_buff_type = io.read(GLB_H_SIZE)
        glb_buff_data = io.read(glb_buff_length)

        [JSON.parse(glb_json_data), glb_buff_data]
    end

    # load image
    def load_image property, image_path
        image = open(image_path, 'rb').read
        img_idx = property["images"].find{|x| x["name"] == "template" }["bufferView"]
        [image, img_idx]
    end

    # Lua Script
    def load_script property, page_size
        require 'erb'
        template = ERB.new open(@vci_script_path).read
        src = template.result(binding)
        src_idx = property["extensions"]["VCAST_vci_embedded_script"]["scripts"][0]["source"]

        return [src, src_idx]
    end

    def mk_data property, glb_buff_data, image, img_idx, src, src_idx
        data = ""
        property["bufferViews"].each_with_index do |x, i|
            case i
            when img_idx
                data += image + FF * padding_size(image.size)
            when src_idx
                data += src + FF * padding_size(src.size)
            else
                len = x["byteLength"]
                data += glb_buff_data[x["byteOffset"], len] + FF * padding_size(len)
            end
        end
        data
    end

    #
    # Create JSON
    #
    def mk_json property, image, img_idx, src, src_idx, data, page_size, meta
        # Update meta data
        vci_meta = property["extensions"]["VCAST_vci_meta"]
        vci_meta["title"] = meta[:title]
        vci_meta["version"] = meta[:version]
        vci_meta["author"] = meta[:author]
        vci_meta["description"] = meta[:description]

        # Adjust for page size
        material = property["materials"].find{|x| x["name"] == "ScreenTexture"}
        material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / page_size).floor(5), 1]

        # buffers/Update bufferViews
        property["bufferViews"][img_idx]["byteLength"] = image.size
        property["bufferViews"][src_idx]["byteLength"] = src.size
        xs = property["bufferViews"]
        (1..xs.size-1).each do |i|
            px = xs[i - 1]
            len = px["byteLength"]
            offset = px["byteOffset"] + len + padding_size(len)
            xs[i]["byteOffset"] = offset
        end

        property["buffers"][0]["byteLength"] = data.size
        json = property.to_json.gsub('/', '\/')
        json.force_encoding("ASCII-8BIT")
    end
end

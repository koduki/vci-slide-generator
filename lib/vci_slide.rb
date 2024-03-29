require 'json'

GLB_H_SIZE = 4
GLB_H_MAGIC = "glTF".b
GLB_H_VERSION = [2].pack("L*")
GLB_JSON_TYPE = "JSON".b
GLB_BUFF_TYPE = "BIN\x00".b
FF = "\x00".b

SLIDE_MATERIAL_NAME="Slide"
SLIDE_TEXTURE_NAME = "Slide-all"

class VCISlide
    attr_accessor :template_vci_path, :vci_script_path, :image_path, :page_size, :output_path, :meta_title, :meta_version, :meta_author, :meta_description, :max_page_index, :max_page_index

    def initialize template=nil, workspace=nil, vci_meta=nil, page_size=nil, max_page_index=nil
        @template_vci_path = template.vci_path unless template == nil
        @vci_script_path = template.vci_script_path unless template == nil
        @image_path = workspace.image_path unless workspace == nil
        @thum_path = workspace.thum_path unless workspace == nil
        @output_path = workspace.vci_output_path unless workspace == nil
        @page_size = page_size
        @max_page_index = max_page_index 
        @meta_title = vci_meta.title unless vci_meta == nil
        @meta_version = vci_meta.version unless vci_meta == nil
        @meta_author = vci_meta.author unless vci_meta == nil
        @meta_description = vci_meta.description unless vci_meta == nil
    end

    def generate
        property, glb_buff_data = load_template(@template_vci_path)
        image, img_idx = load_image(property, @image_path, SLIDE_TEXTURE_NAME)
        thumbnail, thum_idx = load_thumbnail(property, @thum_path)
        src, src_idx = load_script(property, page_size, max_page_index)

        data = mk_data(property, glb_buff_data, image, img_idx, thumbnail, thum_idx, src, src_idx)
        meta = {title:@meta_title, version:@meta_version, author:@meta_author, description:@meta_description}
        json = mk_json(property, image, img_idx, thumbnail, thum_idx, src, src_idx, data, @page_size, meta)

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
        load_template_from_data open(template_vci_path)
    end

    def load_template_from_data file
        io = file
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
    def load_image property, image_path, slide_texture_name
        image = open(image_path, 'rb').read
        img_idx = find_image_index property, slide_texture_name
        [image, img_idx]
    end

    def find_image_index property, slide_texture_name
        property["images"].find{|x| x["name"] == slide_texture_name }["bufferView"]
    end

    # Load Thumbnail
    def load_thumbnail property, thum_path
        thum = open(thum_path, 'rb').read
        vci_meta = property["extensions"]["VCAST_vci_meta"]
        idx = vci_meta["thumbnail"]
        thum_idx = property["images"][idx]["bufferView"]

        [thum, thum_idx]
    end

    # Lua Script
    def load_script property, page_size, max_page_index
        require 'erb'
        template = ERB.new open(@vci_script_path).read
        src = template.result(binding)
        src_idx = property["extensions"]["VCAST_vci_embedded_script"]["scripts"][0]["source"]

        return [src, src_idx]
    end

    def mk_data property, glb_buff_data, image, img_idx, thumbnail, thum_idx, src, src_idx
        data = ""
        property["bufferViews"].each_with_index do |x, i|
            case i
            when img_idx
                data += image + FF * padding_size(image.size)
            when thum_idx
                data += thumbnail + FF * padding_size(thumbnail.size)
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
    def mk_json property, image, img_idx, thumbnail, thum_idx, src, src_idx, data, page_size, meta
        p thum_idx
        p thumbnail.size
        # Update meta data
        vci_meta = property["extensions"]["VCAST_vci_meta"]
        vci_meta["title"] = meta[:title]
        vci_meta["version"] = meta[:version]
        vci_meta["author"] = meta[:author]
        vci_meta["description"] = meta[:description]

        # Adjust for page size
        material = property["materials"].find{|x| x["name"] == SLIDE_MATERIAL_NAME}
        # material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / page_size).floor(5), 1]
        material["pbrMetallicRoughness"]["baseColorTexture"]["extensions"]["KHR_texture_transform"]["scale"] = [(1.0 / max_page_index[:x]).floor(5), (1.0 / max_page_index[:y]).floor(5)]

        # buffers/Update bufferViews
        property["bufferViews"][img_idx]["byteLength"] = image.size
        property["bufferViews"][thum_idx]["byteLength"] = thumbnail.size
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

class Pdf2png
    def initialize
    end

    def transform template, workspace
        r = export_slide template, workspace
        export_thumbnail workspace

        r
    end

    def export_slide template, workspace
        require 'open3'

        #
        # make slide image
        #
        Open3.capture3("pdftoppm #{workspace.pdf_path} #{workspace.dir}/image")
        Open3.capture3("mogrify -format png -resize 800x450 #{workspace.dir}/image*")
        stdout, stderr, status = Open3.capture3("ls -1 #{workspace.dir}/image-*.png|wc -l")
        page_size = stdout.to_i

        max_page_index = {x:template.max_page_x_index, y:(page_size / (template.max_page_x_index * 1.0)).ceil}
        stdout, stderr, status = Open3.capture3("montage -tile #{max_page_index[:x]}x#{max_page_index[:y]} -geometry 100% `ls -1 #{workspace.dir}/image-*.png` #{workspace.image_path}")

        stdout, stderr, status = Open3.capture3("ls -1 #{workspace.dir}/image-*.png|wc -l")
        # debug
        p stdout
        p stderr
        p status

        [page_size, max_page_index]
    end

    def export_thumbnail workspace
        stdout, stderr, status = Open3.capture3("ls -1 #{workspace.dir}/image-*.png|sort|head -1")
        thum_src_path = stdout.to_s.strip
        require 'rmagick'

        height = 512
        width = 512

        image = Magick::Image.from_blob(open(thum_src_path).read).first
        narrow = image.columns > image.rows ? image.rows : image.columns

        thum = image.crop(Magick::CenterGravity, narrow, narrow).resize(width, height)
        thum.write(workspace.thum_path)
    end
end

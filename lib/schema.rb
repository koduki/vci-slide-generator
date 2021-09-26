
VCIMeta = Struct.new :title, :version, :author, :description, :filename, :file, :keyword_init => true

class VCITemplate
    def max_page_x_index = 10
    def vci_path = "/app/resources/template.vci"
    def vci_script_path = "/app/resources/vci-main.lua.erb"
end

class Workspace
    def initialize
        @pdf_name = "slide.pdf"
        @vci_output_path = "output.vci" 
        @image_path = "slide.png"
        @thum_path = "thum.png"

        id = sprintf("%04d", rand(1000))
        @dir = "/tmp/vci_slide/#{id}"

        setup @dir
    end

    def setup work_dir
        require 'open3'
        Open3.capture3("rm -rf #{work_dir}")
        Open3.capture3("mkdir -p #{work_dir}")
    end

    def dir = @dir
    def pdf_path = "#{@dir}/#{@pdf_name}"
    def vci_output_path = "#{@dir}/#{@vci_output_path}"
    def image_path = "#{@dir}/#{@image_path}"
    def thum_path = "#{@dir}/#{@thum_path}"
end
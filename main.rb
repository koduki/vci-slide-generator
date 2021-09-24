require 'sinatra'
require './lib/vci_slide.rb'

MAX_PAGE_X_INDEX = 10

get '/' do
    erb :index
end

post '/generate' do
    init()

    title = params[:title]
    version = params[:version]
    author = params[:author]
    description = params[:description]
    filename = params[:file][:filename]
    file = params[:file][:tempfile]
    pdf_path = "/tmp/vci_slide/slide.pdf"
    File.open(pdf_path, 'wb') do |f|
        f.write(file.read)
    end

    template_vci_path = "/app/resources/template.vci"
    vci_script_path = "/app/resources/vci-main.lua.erb"
    output_vci_path = "/tmp/vci_slide/output.vci" 
    image_path = "/tmp/vci_slide/slide.png"
    thum_path = "/tmp/vci_slide/thum.png"
    page_count, max_page_index = pdf2png(pdf_path, image_path, thum_path)

    vci_slide = VCISlide.new template_vci_path, vci_script_path, image_path, thum_path, page_count, max_page_index, output_vci_path
    vci_slide.meta_title = title
    vci_slide.meta_version = version
    vci_slide.meta_author = author
    vci_slide.meta_description = description

    vci_slide.generate

    send_file output_vci_path, {filename:"slide.vci", disposition:"attachment"}
end

def init
    require 'open3'

    Open3.capture3('rm -rf /tmp/vci_slide')
    Open3.capture3('mkdir -p /tmp/vci_slide')
end

def pdf2png pdf_path, image_path, thum_path
    require 'open3'

    #
    # make slide image
    #
    Open3.capture3("pdftoppm #{pdf_path} /tmp/vci_slide/image")
    Open3.capture3("mogrify -format png -resize 800x450 /tmp/vci_slide/image*")
    stdout, stderr, status = Open3.capture3("ls -1 /tmp/vci_slide/image-*.png|wc -l")
    page_size = stdout.to_i

    max_page_index = {x:MAX_PAGE_X_INDEX, y:(page_size / (MAX_PAGE_X_INDEX * 1.0)).ceil}
    stdout, stderr, status = Open3.capture3("montage -tile #{max_page_index[:x]}x#{max_page_index[:y]} -geometry 100% `ls -1 /tmp/vci_slide/image-*.png` #{image_path}")
    
    stdout, stderr, status = Open3.capture3("ls -1 /tmp/vci_slide/image-*.png|wc -l")
    # debug
    p stdout
    p stderr
    p status

    #
    # make thumbnail
    #
    stdout, stderr, status = Open3.capture3("ls -1 /tmp/vci_slide/image-*.png|sort|head -1")
    thum_src_path = stdout.to_s.strip
    p thum_src_path
    require 'rmagick'

    height = 512
    width = 512

    image = Magick::Image.from_blob(open(thum_src_path).read).first
    narrow = image.columns > image.rows ? image.rows : image.columns

    thum = image.crop(Magick::CenterGravity, narrow, narrow).resize(width, height)
    thum.write(thum_path)

    [page_size, max_page_index]
end

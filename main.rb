require 'sinatra'
require "json"

require './lib/vci_slide.rb'
require './lib/tso.rb'

MAX_PAGE_X_INDEX = 10

get '/' do
    erb :index
end

post '/generate' do
    title = params[:title].strip
    version = params[:version].strip
    author = params[:author].strip
    description = params[:description].strip
    filename = params[:file][:filename]
    file = params[:file][:tempfile]
    token = params[:token].strip

    template_vci_path = "/app/resources/template.vci"
    vci_script_path = "/app/resources/vci-main.lua.erb"

    reqid = sprintf("%04d", rand(1000))
    work_dir = "/tmp/vci_slide/#{reqid}"
    pdf_name = "slide.pdf"
    output_vci_name = "output.vci" 
    image_name = "slide.png"
    thum_name = "thum.png"

    init work_dir

    File.open("#{work_dir}/#{pdf_name}", 'wb') do |f|
        f.write(file.read)
    end

    page_count, max_page_index = pdf2png(work_dir, pdf_name, image_name, thum_name)

    vci_slide = VCISlide.new template_vci_path, vci_script_path, work_dir, image_name, thum_name, page_count, max_page_index, output_vci_name
    vci_slide.meta_title = title
    vci_slide.meta_version = version
    vci_slide.meta_author = author
    vci_slide.meta_description = description

    vci_slide.generate

    # Transfer to TSO
    vci = open("#{work_dir}/#{output_vci_name}")
    puts "Upload: #{work_dir}/#{output_vci_name}"
    tso = Tso.new(token)
    r = tso.upload_vci vci
    r.to_json

    # redirect to('/')
    erb :index
    # send_file output_vci_path, {filename:"slide.vci", disposition:"attachment"}
end

def init work_dir
    require 'open3'

    Open3.capture3("rm -rf #{work_dir}")
    Open3.capture3("mkdir -p #{work_dir}")
end

def pdf2png work_dir, pdf_name, image_name, thum_name
    r = export_slide work_dir, pdf_name, image_name
    export_thumbnail work_dir, thum_name

    r
end

def export_slide work_dir, pdf_name, image_name
    require 'open3'

    #
    # make slide image
    #
    Open3.capture3("pdftoppm #{work_dir}/#{pdf_name} #{work_dir}/image")
    Open3.capture3("mogrify -format png -resize 800x450 #{work_dir}/image*")
    stdout, stderr, status = Open3.capture3("ls -1 #{work_dir}/image-*.png|wc -l")
    page_size = stdout.to_i

    max_page_index = {x:MAX_PAGE_X_INDEX, y:(page_size / (MAX_PAGE_X_INDEX * 1.0)).ceil}
    stdout, stderr, status = Open3.capture3("montage -tile #{max_page_index[:x]}x#{max_page_index[:y]} -geometry 100% `ls -1 #{work_dir}/image-*.png` #{work_dir}/#{image_name}")
    
    stdout, stderr, status = Open3.capture3("ls -1 #{work_dir}/image-*.png|wc -l")
    # debug
    p stdout
    p stderr
    p status

    [page_size, max_page_index]
end

def export_thumbnail work_dir, thum_name
    stdout, stderr, status = Open3.capture3("ls -1 #{work_dir}/image-*.png|sort|head -1")
    thum_src_path = stdout.to_s.strip
    require 'rmagick'

    height = 512
    width = 512

    image = Magick::Image.from_blob(open(thum_src_path).read).first
    narrow = image.columns > image.rows ? image.rows : image.columns

    thum = image.crop(Magick::CenterGravity, narrow, narrow).resize(width, height)
    thum.write("#{work_dir}/#{thum_name}")
end
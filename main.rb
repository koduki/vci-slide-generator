require 'sinatra'
require './lib/vci_slide.rb'
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
    pdf_path = "/tmp/vci_slide/#{filename}"
    File.open(pdf_path, 'wb') do |f|
        f.write(file.read)
    end

    template_vci_path = "/app/resources/template.vci"
    vci_script_path = "/app/resources/vci-main.lua.erb"
    output_vci_path = "/tmp/vci_slide/output2.vci" 
    image_path = "/tmp/vci_slide/slide.png"
    page_count = pdf2png(pdf_path, image_path)

    vci_slide = VCISlide.new template_vci_path, vci_script_path, image_path, page_count, output_vci_path
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

def pdf2png pdf_path, image_path
    require 'open3'

    Open3.capture3("pdftoppm #{pdf_path} /tmp/vci_slide/image")
    Open3.capture3("mogrify -format png -resize 800x450 /tmp/vci_slide/image*")
    stdout, stderr, status = Open3.capture3("convert +append `ls -1 /tmp/vci_slide/image-*.png` #{image_path}")
p stdout
p stderr
p status
    stdout, stderr, status = Open3.capture3("ls -1 /tmp/vci_slide/image-*.png|wc -l")
    stdout.to_i
end
require 'sinatra'
require "json"

require './lib/schema.rb'
require './lib/vci_slide.rb'
require './lib/tso.rb'

get '/' do
    erb :index
end

post '/generate' do
    p params[:author].strip
    vci_meta = VCIMeta.new(
        title: params[:title].strip,
        version: params[:version].strip,
        author: params[:author].strip,
        description: params[:description].strip
    )

    file = params[:file][:tempfile]
    token = params[:token].strip

    template = VCITemplate.new
    workspace = Workspace.new

    # upload
    upload workspace.pdf_path, file

    # translate to image
    page_size, max_page_index = Pdf2png.new.transform template, workspace

    # translate to vci
    vci_slide = VCISlide.new template, workspace, vci_meta, page_size, max_page_index
    vci_slide.generate

    # transfer to TSO
    vci = open(workspace.vci_output_path)
    tso = Tso.new(token)
    r = tso.upload_vci(vci).to_json

    erb :index
    # send_file workspace.vci_output_path, {filename:"slide.vci", disposition:"attachment"}
end

def upload upload_path, file
    File.open(upload_path, 'wb') do |f|
        f.write(file.read)
    end
end
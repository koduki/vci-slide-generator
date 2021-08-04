require './lib/vci_slide.rb'

cmd = ARGV[0]
subcmd = ARGV[1]

if cmd == "export"
    template_vci_path = ARGV[2]
    vci_slide = VCISlide.new template_vci_path, nil, nil, nil, nil
    property, glb_buff_data = vci_slide.load_template(template_vci_path)

    case subcmd
    when "json" then
        require 'json'
        puts property.to_json
    when "image" then
        texture_name = ARGV[3] # "Slide-all"
        img_output_path = ARGV[4]

        img_idx = vci_slide.find_image_index property, texture_name
        img_len = property["bufferViews"][img_idx]["byteLength"]

        
        bfv = property["bufferViews"][img_idx]
        img_data = glb_buff_data[bfv["byteOffset"], bfv["byteLength"]];1
        open(img_output_path, 'wb') do |f|
            f.write(img_data.unpack('C*').pack('C*'))
        end;

    else
        puts "json|image"
    end
end





require 'erb'
template = ERB.new open(ARGV[0]).read
page=ARGV[1].to_i

md = template.result(binding)

puts md
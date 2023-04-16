require 'yaml'

mappath = ARGV[0]
outputpath = ARGV[1]

panels = []

File.readlines(mappath).each do |line|
  line.match(/node name=\"(.*)\" parent=\"Panels\/(.*)\" instance/) do |m|
    panels << {"id" => m[2] + "/" + m[1]}
  end
end

File.write(outputpath, panels.to_yaml)

require 'yaml'

configpath = ARGV[0]
outputpath = ARGV[1]

config = YAML.load_file(configpath)
output = config.map do |panel|
  ret = panel
  if ret["color"].kind_of? String
    ret["color"] = [ret["color"]]
  end
  ret
end.map do |panel|
  ret = {}
  ret["id"] = "\"#{panel["id"]}\""
  ret["color"] = "[\"" + panel["color"].join("\",\"") + "\"]"
  ret["tag"] = "\"#{panel["tag"]}\""
  if panel.include? "subtag"
    ret["subtag"] = "\"#{panel["subtag"]}\""
  end
  if panel.include? "link"
    ret["link"] = "\"#{panel["link"]}\""
  end
  if panel.include? "copy_to_sign"
    ret["copy_to_sign"] = "\"#{panel["copy_to_sign"]}\""
  end
    ret
end.map do |panel|
  "{" + panel.to_a.map do |element|
    "\"#{element[0]}\":#{element[1]}"
  end.join(",") + "}"
end.join(",")

header = "extends Node\n\nvar panels = ["
footer = "]"

File.write(outputpath, header + output + footer)
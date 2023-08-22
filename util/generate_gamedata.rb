require 'set'
require 'yaml'

configpath = ARGV[0]
outputpath = ARGV[1]

CLASSIFICATION_NORMAL = 1
CLASSIFICATION_REDUCED = 2
CLASSIFICATION_INSANITY = 4

panel_to_id = {}
door_groups = {}

panel_output = []
door_ids_by_item_id = {}
painting_ids_by_item_id = {}
panel_ids_by_location_id = {}
classification_by_location_id = {}
mentioned_doors = Set[]
mentioned_paintings = Set[]
painting_output = {}

config = YAML.load_file(configpath)
config.each do |room_name, room_data|
  if room_data.include? "panels"
    room_data["panels"].each do |panel_name, panel|
      full_name = "#{room_name} - #{panel_name}"
      panel_to_id[full_name] = panel["id"]

      ret = {}
      ret["id"] = "\"#{panel["id"]}\""
      if panel.include? "colors"
        if panel["colors"].kind_of? String
          ret["color"] = "[\"#{panel["colors"]}\"]"
        else
          ret["color"] = "[\"" + panel["colors"].join("\",\"") + "\"]"
        end
      else
        ret["color"] = "[\"white\"]"
      end
      ret["tag"] = "\"#{panel["tag"]}\""
      if panel.include? "subtag"
        ret["subtag"] = "\"#{panel["subtag"]}\""
      end
      if panel.include? "link"
        ret["link"] = "\"#{panel["link"]}\""
      end
      if panel.include? "copy_to_sign"
        copytos = []
        if panel["copy_to_sign"].kind_of? String
          copytos = [panel["copy_to_sign"]]
        else
          copytos = panel["copy_to_sign"]
        end
        ret["copy_to_sign"] = "[\"" + copytos.join("\",\"") + "\"]"
      end
      if panel.include? "achievement"
        ret["achievement"] = "\"#{panel["achievement"]}\""
      end
      panel_output << ret

      panel_ids_by_location_id[full_name] = [panel["id"]]

      classification_by_location_id[full_name] ||= 0
      classification_by_location_id[full_name] += CLASSIFICATION_INSANITY

      if panel.include? "check" and panel["check"]
        classification_by_location_id[full_name] += CLASSIFICATION_NORMAL

        unless panel.include? "exclude_reduce" and panel["exclude_reduce"]
          classification_by_location_id[full_name] += CLASSIFICATION_REDUCED
        end
      end
    end
  end

  if room_data.include? "paintings"
    room_data["paintings"].each do |painting|
      painting_output[painting["id"]] = painting
    end
  end
end

config.each do |room_name, room_data|
  if room_data.include? "doors"
    room_data["doors"].each do |door_name, door|
      full_name = "#{room_name} - #{door_name}"

      if not (door.include? "skip_location" and door["skip_location"]) and
         not (door.include? "event" and door["event"]) and
         door.include? "panels" then

        chosen_name = full_name
        if door.include? "location_name"
          chosen_name = door["location_name"]
        else
          panels_per_room = {}
          door["panels"].each do |panel_identifier|
            if panel_identifier.kind_of? String
              panels_per_room[room_name] ||= []
              panels_per_room[room_name] << panel_identifier
            else
              panels_per_room[panel_identifier["room"]] ||= []
              panels_per_room[panel_identifier["room"]] << panel_identifier["panel"]
            end
          end

          chosen_name = panels_per_room.map do |room_name, panels|
            room_name + " - " + panels.join(", ")
          end.join(" and ")
        end

        panel_ids_by_location_id[chosen_name] = door["panels"].map do |panel_identifier|
          other_name = ""
          if panel_identifier.kind_of? String
            other_name = "#{room_name} - #{panel_identifier}"
          else
            other_name = "#{panel_identifier["room"]} - #{panel_identifier["panel"]}"
          end
          panel_to_id[other_name]
        end

        classification_by_location_id[chosen_name] ||= 0
        classification_by_location_id[chosen_name] += CLASSIFICATION_NORMAL

        if door.include? "include_reduce" and door["include_reduce"]
          classification_by_location_id[chosen_name] += CLASSIFICATION_REDUCED
        end
      end

      if not (door.include? "skip_item" and door["skip_item"]) and
         not (door.include? "event" and door["event"]) then

        chosen_name = full_name
        if door.include? "item_name"
          chosen_name = door["item_name"]
        end

        if door.include? "id"
          internal_door_ids = []
          if door["id"].kind_of? String
            internal_door_ids = [door["id"]]
          else
            internal_door_ids = door["id"]
          end
          
          if door.include? "group"
            door_groups[door["group"]] ||= Set[]
            door_groups[door["group"]].merge(internal_door_ids)
          end

          door_ids_by_item_id[chosen_name] = internal_door_ids
          mentioned_doors.merge(internal_door_ids)
        end

        if door.include? "painting_id"
          internal_painting_ids = []
          if door["painting_id"].kind_of? String
            internal_painting_ids = [door["painting_id"]]
          else
            internal_painting_ids = door["painting_id"]
          end

          painting_ids_by_item_id[chosen_name] = internal_painting_ids
          mentioned_paintings.merge(internal_painting_ids)
        end
      end
    end
  end
end

door_groups.each do |group_name, door_ids|
  door_ids_by_item_id[group_name] = door_ids.to_a
end

File.open(outputpath, "w") do |f|
  f.write "extends Node\n\nvar panels = ["
  f.write(panel_output.map do |panel|
    "{" + panel.to_a.map do |element|
      "\"#{element[0]}\":#{element[1]}"
    end.join(",") + "}"
  end.join(","))
  f.write "]\nvar door_ids_by_item_id = {"
  f.write(door_ids_by_item_id.map do |item_id, door_ids|
    "\"#{item_id}\":[" + door_ids.map do |door_id|
      "\"#{door_id}\""
    end.join(",") + "]"
  end.join(","))
  f.write "}\nvar painting_ids_by_item_id = {"
  f.write(painting_ids_by_item_id.map do |item_id, painting_ids|
    "\"#{item_id}\":[" + painting_ids.map do |painting_id|
      "\"#{painting_id}\""
    end.join(",") + "]"
  end.join(","))
  f.write "}\nvar panel_ids_by_location_id = {"
  f.write(panel_ids_by_location_id.map do |location_id, panel_ids|
    "\"#{location_id}\":[" + panel_ids.map do |panel_id|
      "\"#{panel_id}\""
    end.join(",") + "]"
  end.join(","))
  f.write "}\nvar mentioned_doors = ["
  f.write(mentioned_doors.map do |door_id|
    "\"#{door_id}\""
  end.join(","))
  f.write "]\nvar mentioned_paintings = ["
  f.write(mentioned_paintings.map do |painting_id|
    "\"#{painting_id}\""
  end.join(","))
  f.write "]\nvar paintings = {"
  f.write(painting_output.map do |painting_id, painting|
    "\"#{painting_id}\":{\"orientation\":\"#{painting["orientation"]}\",\"move\":#{painting.include? "move" and painting["move"]}}"
  end.join(","))
  f.write "}\nvar classification_by_location_id = {"
  f.write(classification_by_location_id.map do |location_id, classification|
    "\"#{location_id}\":#{classification}"
  end.join(","))
  f.write "}"
end

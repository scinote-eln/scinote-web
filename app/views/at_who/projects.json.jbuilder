json.items do
  json.array! @projects do |project|
    json.partial! 'annotation_item', record: project, type: 'prj'
  end
end

json.limit_reached @limit_reached
json.team @team_id

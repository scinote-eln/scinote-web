json.groups do
  json.array! @groups do |group|
    json.project_name sanitize_input(group[:project_name])
    json.items do
      json.array! group[:records] do |experiment|
        json.partial! 'annotation_item', record: experiment, type: 'exp'
      end
    end
  end
end

json.limit_reached @limit_reached
json.team @team_id

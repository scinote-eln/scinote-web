json.repositories do
  json.array! @repositories do |repository|
    json.partial! 'repository_option', repository: repository
  end
end

json.team @team_id

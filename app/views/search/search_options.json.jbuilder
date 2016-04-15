json.suggestions(@results) do |r|
  if r.first.is_a? Comment
    json.value r.first.message
  elsif r.first.is_a? Asset
   json.value r.first.file_file_name
  elsif r.first.is_a? AssetTextDatum
   json.value r.first.data
  else
    json.value r.first.name
  end
end
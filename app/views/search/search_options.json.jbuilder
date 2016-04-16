json.suggestions(@results) do |result|
  result.each do |r|
    json.value r
  end
end
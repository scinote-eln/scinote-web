json.items do
  json.array! @items do |item|
    json.partial! 'search_item', item: item
  end
end

json.limit_reached @limit_reached

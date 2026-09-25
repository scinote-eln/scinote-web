json.users do
  json.array! @users do |user|
    json.partial! 'user', user: user
  end
end

json.limit_reached @limit_reached

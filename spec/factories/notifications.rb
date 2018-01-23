FactoryBot.define do
  factory :notification do
    title '<i>Admin</i> was added as Owner to project ' \
          '<strong>Demo project - qPCR</strong> by <i>User</i>.'
    message 'Project: <a href=\"/projects/3\"> Demo project - qPCR</a>'
    type_of 'assignment'
  end
end

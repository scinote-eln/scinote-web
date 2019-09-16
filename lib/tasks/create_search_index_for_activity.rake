# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
namespace :activities do
  desc 'Migrate old TinyMCE images to new polymorphic format' \
       'IT SHOULD BE RUN ONE TIME ONLY'
  task create_activities_search_index: :environment do
    Activity.where(search_index: nil).each do |activity|
      activity.update(search_index: activity.get_activity_text)
    end
  end
end
# rubocop:enable Metrics/LineLength
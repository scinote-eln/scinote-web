# frozen_string_literal: true

class ConvertUserTimezonesToIanaFormat < ActiveRecord::Migration[7.0]
  def up
    # Build a mapping from ActiveSupport::TimeZone name to IANA name
    tz_map = {}
    ActiveSupport::TimeZone.all.each do |tz|
      tz_map[tz.name] = tz.tzinfo.name
    end

    # Update each user's timezone to the IANA version
    User.find_each do |user|
      tz = user.settings['time_zone']
      next unless tz.present? && tz_map[tz]

      user.settings['time_zone'] = tz_map[tz]
      user.save!
    end
  end

  def down
    # Build a reverse mapping in case you need to rollback
    reverse_tz_map = {}
    ActiveSupport::TimeZone.all.each do |tz|
      reverse_tz_map[tz.tzinfo.name] = tz.name
    end

    User.find_each do |user|
      tz = user.settings['time_zone']
      next unless tz.present? && reverse_tz_map[tz]

      user.settings['time_zone'] = reverse_tz_map[tz]
      user.save!
    end
  end
end

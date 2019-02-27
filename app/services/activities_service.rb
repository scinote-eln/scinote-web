# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(team_ids, filters = {})
    if filters[:subjects].present?
      query = Activity.where(
        filters[:subjects].map { '(subject_type = ? AND subject_id IN(?))' }
                          .join(' OR '),
        *filters[:subjects].flatten
      )
    else
      query = Activity
    end

    query = query.where(team_id: team_ids)
    query = query.where(owner_id: filters[:users]) if filters[:users]
    query = query.where(type_of: filters[:types]) if filters[:types]

    if filters[:from_date] && filters[:to_date]
      activities = query.where(
        'created_at <= :from AND created_at >= :to',
        from: Time.zone.parse(filters[:from_date]).beginning_of_day.utc,
        to: Time.zone.parse(filters[:to_date]).end_of_day.utc
      )
    elsif filters[:from_date] && !filters[:to_date]
      activities = query.where(
        'created_at <= :from',
        from: Time.zone.parse(filters[:from_date]).beginning_of_day.utc
      )
    else
      activities = query
    end

    activities = activities.order(created_at: :desc)
                           .limit(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    loaded = activities.length
    results = activities.group_by do |activity|
      Time.zone.at(activity.created_at).to_date.to_s
    end

    return results if loaded < Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT

    last_date = results.keys.last
    activities = query.where(
      'created_at <= :from AND created_at >= :to',
      from: Time.zone.parse(last_date).beginning_of_day.utc,
      to: Time.zone.parse(last_date).end_of_day.utc
    )
    more_left = query.where(
      'created_at < :from',
      from: Time.zone.parse(last_date).end_of_day.utc
    ).exists?
    results[last_date] = activities.to_a
    [results, more_left]
  end
end

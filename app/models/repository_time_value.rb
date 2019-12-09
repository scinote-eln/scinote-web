# frozen_string_literal: true

class RepositoryTimeValue < RepositoryDateTimeValueBase
  def data_changed?(new_data)
    formatted != formatted(new_date: new_data)
  end

  def formatted(new_date: nil)
    super(:time, new_date: new_date)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end
end

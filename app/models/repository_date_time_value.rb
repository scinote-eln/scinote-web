# frozen_string_literal: true

class RepositoryDateTimeValue < RepositoryDateTimeValueBase
  def data_changed?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.to_i != data.to_i
  end

  def formatted
    super(:full_with_comma)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  alias export_formatted formatted
end

# frozen_string_literal: true

class RepositoryTimeValue < RepositoryDateTimeValueBase
  def data_changed?(new_data)
    formatted != formatted(new_date: new_data)
  end

  def formatted(new_date: nil)
    super(:time, new_date: new_date)
  end
end

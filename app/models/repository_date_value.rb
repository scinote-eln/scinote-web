# frozen_string_literal: true

class RepositoryDateValue < RepositoryDateTimeValueBase
  def data_changed?(new_data)
    formatted != formatted(new_date: new_data)
  end

  def formatted(new_date: nil)
    super(:full_date, new_date: new_date)
  end
end

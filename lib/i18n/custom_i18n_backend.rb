# frozen_string_literal: true

class CustomI18nBackend < I18n::Backend::Simple
  attr_accessor :date_format

  # Gets I18n configuration object.
  def date_format
    Thread.current[:i18n_date_format] ||= Constants::DEFAULT_DATE_FORMAT
  end

  # Sets I18n configuration object.
  def date_format=(value)
    Thread.current[:i18n_date_format] = value
  end

  def localize(locale, object, format = :default, options = {})
    options[:date_format] ||= date_format
    super(locale, object, format, options)
  end
end

# frozen_string_literal: true

class CustomI18nBackend < I18n::Backend::Simple
  attr_accessor :date_format

  def localize(locale, object, format = :default, options = {})
    options[:date_format] ||= @date_format || Constants::DEFAULT_DATE_FORMAT
    super(locale, object, format, options)
  end
end

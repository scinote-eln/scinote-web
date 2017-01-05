module InputSanitizeHelper
  def sanitize_input(text)
    ActionController::Base.helpers.sanitize(text,
                                            tags: Constants::WHITELISTED_TAGS)
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end
end

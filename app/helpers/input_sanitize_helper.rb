module InputSanitizeHelper
  def sanitize_input(text)
    ActionController::Base.helpers.sanitize(text,
                                            tags: Constants::WHITELISTED_TAGS)
  end
end

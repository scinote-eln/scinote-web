module InputSanitizeHelper
  def sanitize_input(text)
    ActionController::Base.helpers.sanitize(
      text,
      tags: Constants::WHITELISTED_TAGS,
      attributes: Constants::WHITELISTED_ATTRIBUTES
    )
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end

  def custom_auto_link(text, args)
    args[:sanitize] = false
    sanitize_input(auto_link(text, args))
  end
end

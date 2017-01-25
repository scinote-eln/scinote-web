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

  def custom_auto_link(text, simple_format = true, org = nil)
    text = if simple_format
             simple_format(sanitize_input(text))
           else
             sanitize_input(text)
           end
    auto_link(
      smart_annotation_parser(text, org),
      link: :urls,
      sanitize: false,
      html: { target: '_blank' }
    ).html_safe
  end
end

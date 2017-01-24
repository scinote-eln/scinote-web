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

  def custom_auto_link(text, org = nil)
    auto_link(
      smart_annotation_parser(simple_format(sanitize_input(text)), org),
      link: :urls,
      sanitize: false,
      html: { target: '_blank' }
    ).html_safe
  end
end

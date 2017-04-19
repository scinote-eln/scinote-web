module InputSanitizeHelper
  def sanitize_input(
    text,
    tags = [],
    attributes = []
  )
    ActionController::Base.helpers.sanitize(
      text,
      tags: Constants::WHITELISTED_TAGS + tags,
      attributes: Constants::WHITELISTED_ATTRIBUTES + attributes
    )
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end

  def custom_auto_link(text, options = {})
    simple_format = options.fetch(:simple_format) { true }
    team = options[:team],
    wrapper_tag = options.fetch(:wrapper_tag) { {} }
    tags = options.fetch(:tags) { [] }
    text = if simple_format
             simple_format(sanitize_input(text), {}, wrapper_tag)
           else
             sanitize_input(text, tags)
           end
    auto_link(
      smart_annotation_parser(text, team),
      link: :urls,
      sanitize: false,
      html: { target: '_blank' }
    ).html_safe
  end
end

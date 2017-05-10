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
    simple_f = options.fetch(:simple_format) { true }
    team = options.fetch(:team) { nil }
    wrapper_tag = options.fetch(:wrapper_tag) { {} }
    tags = options.fetch(:tags) { [] }
    fromat_opt = wrapper_tag.merge(sanitize: false)
    text = sanitize_input(text, tags)
    text = simple_format(sanitize_input(text), {}, fromat_opt) if simple_f
    auto_link(
      smart_annotation_parser(text, team),
      link: :urls,
      sanitize: false,
      html: { target: '_blank' }
    ).html_safe
  end
end

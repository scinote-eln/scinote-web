require 'sanitize'

module InputSanitizeHelper
  # Rails default ActionController::Base.helpers.sanitize method call
  # the ActiveRecord connecton method on the caller object which in
  # our cases throws an error when called from not ActiveRecord objects
  # such as SamplesDatatables
  def sanitize_input(html, tags = [], attributes = [])
    Sanitize.fragment(
      html,
      elements: Constants::WHITELISTED_TAGS + tags,
      attributes: { all: Constants::WHITELISTED_ATTRIBUTES + attributes },
      css: Constants::WHITELISTED_CSS_ATTRIBUTES
    ).html_safe
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end

  def custom_auto_link(text, options = {})
    simple_f = options.fetch(:simple_format) { true }
    team = options.fetch(:team) { nil }
    wrapper_tag = options.fetch(:wrapper_tag) { {} }
    tags = options.fetch(:tags) { [] }
    format_opt = wrapper_tag.merge(sanitize: false)
    base64_encoded_imgs = options.fetch(:base64_encoded_imgs) { false }
    text = sanitize_input(text, tags)
    text = simple_format(sanitize_input(text), {}, format_opt) if simple_f
    auto_link(
      smart_annotation_parser(text, team, base64_encoded_imgs),
      link: :urls,
      sanitize: false,
      html: { target: '_blank' }
    ).html_safe
  end
end

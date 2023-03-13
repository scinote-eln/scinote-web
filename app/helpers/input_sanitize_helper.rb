# frozen_string_literal: true

require 'sanitize'

module InputSanitizeHelper
  def sanitize_input(html, _tags = [], _attributes = [])
    Sanitize.fragment(html, Constants::INPUT_SANITIZE_CONFIG).html_safe
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end

  def custom_auto_link(text, options = {})
    simple_f = options.fetch(:simple_format, true)
    team = options.fetch(:team, nil)
    wrapper_tag = options.fetch(:wrapper_tag) { {} }
    tags = options.fetch(:tags) { [] }
    preview_repository = options.fetch(:preview_repository, false)
    format_opt = wrapper_tag.merge(sanitize: false)
    base64_encoded_imgs = options.fetch(:base64_encoded_imgs, false)
    text = simple_format(text, {}, format_opt) if simple_f
    if text =~ SmartAnnotations::TagToHtml::USER_REGEX || text =~ SmartAnnotations::TagToHtml::REGEX
      text = smart_annotation_parser(text, team, base64_encoded_imgs, preview_repository)
    end
    text = sanitize_input(text, tags)
    auto_link(
      text,
      html: { target: '_blank' },
      link: :urls,
      sanitize: false
    ).html_safe
  end
end

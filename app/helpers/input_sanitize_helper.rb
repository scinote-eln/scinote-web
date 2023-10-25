# frozen_string_literal: true

require 'sanitize'
require 'cgi'

module InputSanitizeHelper
  def sanitize_input(html, _tags = [], _attributes = [], sanitizer_config: nil)
    config =
      if Rails.application.config.x.custom_sanitizer_config.present?
        Rails.application.config.x.custom_sanitizer_config
      elsif sanitizer_config.present?
        sanitizer_config
      else
        Constants::INPUT_SANITIZE_CONFIG
      end
    Sanitize.fragment(html, config).html_safe
  end

  def escape_input(text)
    ERB::Util.html_escape(text)
  end

  def unescape_input(text)
    CGI.unescapeHTML(text)
  end

  def smart_annotation_text(text)
    if text =~ SmartAnnotations::TagToText::USER_REGEX || text =~ SmartAnnotations::TagToText::ITEMS_REGEX
      text = SmartAnnotations::TagToText.new(nil, nil, text, is_shared_object: true).text
    end

    sanitize_input(text)
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

    # allow base64 images when sanitizing if base64_encoded_imgs is true
    sanitizer_config = Constants::INPUT_SANITIZE_CONFIG.deep_dup
    text = sanitize_input(text, tags, sanitizer_config: sanitizer_config)

    if text =~ SmartAnnotations::TagToHtml::USER_REGEX || text =~ SmartAnnotations::TagToHtml::REGEX
      text = smart_annotation_parser(text, team, base64_encoded_imgs, preview_repository)
    end
    auto_link(
      text,
      html: { target: '_blank' },
      link: :urls,
      sanitize: false
    ).html_safe
  end
end

# frozen_string_literal: true

module FormTagHelper
  def recaptcha_input_tag
    if Rails.configuration.x.enable_recaptcha
      res = "<div class='form-group sci-input-container"
      res << 'has-error' if flash[:recaptcha_error]
      res << "'>"
      res << label_tag(:recaptcha_label, 'Let us know you’re human. Enter the captcha below.')
      res << recaptcha_tags
      if flash[:recaptcha_error]
        res << "<span class='help-block'>"
        res << flash[:recaptcha_error]
        res << '</span>'
      end
      res << '</div>'
      res.html_safe
    end
  end
end

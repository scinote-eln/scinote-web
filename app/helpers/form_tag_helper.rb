module FormTagHelper
  def recaptcha_input_tag
    if Rails.configuration.x.enable_recaptcha
      res = "<div class='form-group sci-input-container"
      res << 'has-error' if flash[:recaptcha_error]
      res << "'>"
      res << label_tag(:recaptcha_label, I18n.t('users.registrations.new.captcha_description'))
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

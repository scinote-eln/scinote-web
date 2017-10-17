module FormTagHelper
  def recaptcha_input_tag
    if Rails.configuration.x.enable_recaptcha
      res = "<div class='form-group "
      res << 'has-error' if flash[:recaptcha_error]
      res << "'>"
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

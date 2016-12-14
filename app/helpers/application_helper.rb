module ApplicationHelper
  def module_page?
    controller_name == 'my_modules'
  end

  def experiment_page?
    controller_name == 'experiments'
  end

  def project_page?
    controller_name == 'projects' ||
      (controller_name == 'reports' && action_name == 'index')
  end

  def display_tooltip(message, len = Constants::NAME_TRUNCATION_LENGTH)
    if message.strip.length > Constants::NAME_TRUNCATION_LENGTH
      "<div class='modal-tooltip'>#{truncate(message.strip, length: len)} \
        <span class='modal-tooltiptext'>#{message.strip}</span></div>".html_safe
    else
      truncate(message.strip, length: len)
    end
  end
end

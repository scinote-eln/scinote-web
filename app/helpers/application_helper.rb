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

  def sample_types_page_project?
    controller_name == 'sample_types' &&
      @my_module.nil? &&
      @experiment.nil?
  end

  def sample_groups_page_project?
    controller_name == 'sample_groups' &&
      @my_module.nil? &&
      @experiment.nil?
  end

  def sample_types_page_my_module?
    controller_name == 'sample_types' && !@my_module.nil?
  end

  def sample_groups_page_my_module?
    controller_name == 'sample_groups' && !@my_module.nil?
  end

  def sample_groups_page_experiment?
    controller_name == 'sample_groups' &&
      @my_module.nil? &&
      !@experiment.nil?
  end

  def sample_types_page_expermient?
    controller_name == 'sample_types' &&
      @my_module.nil? &&
      !@experiment.nil?
  end

  def smart_annotation_parser(text)
    sa_reg = /\[\#(.*?)~(prj|exp|tsk|sam)~([0-9]+)\]/
    new_text = text.gsub(sa_reg) do |el|
      match = el.match(sa_reg)
      case match[2]
      when 'prj'
        link_to match[1], project_path(match[3].to_i)
      when 'exp'
        link_to match[1], canvas_experiment_path(match[3].to_i)
      when 'tsk'
        link_to match[1], protocols_my_module_path(match[3].to_i)
      when 'sam'
        sample = Sample.find_by_id(match[3])
        if sample
          link_to match[1],
                  samples_project_path(sample
                                       .organization
                                       .projects
                                       .first)
        end
      end
    end

    sa_user = /\[\@(.*?)~([0-9]+)\]/
    new_text = new_text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      user = User.find_by_id(match[2].to_i)
      "<span>#{image_tag avatar_path(user, :icon_small)} " \
      "#{user.full_name}</span>" if user
    end
    new_text
  end
end

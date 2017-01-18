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
    sa_reg = /\[\#(.*?)~(prj|exp|tsk|sam)~([0-9a-zA-Z]+)\]/
    new_text = text.gsub(sa_reg) do |el|
      match = el.match(sa_reg)
      case match[2]
      when 'prj'
        project = Project.find_by_id(match[3].base62_decode)
        next unless project
        if project.archived?
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to project.name,
                     projects_archive_path} #{t'atwho.res.archived'}"
        else
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to project.name,
                     project_path(project)}"
        end
      when 'exp'
        experiment = Experiment.find_by_id(match[3].base62_decode)
        next unless experiment
        if experiment.archived?
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to experiment.name,
                     experiment_archive_project_path(experiment.project)} " \
          "#{t'atwho.res.archived'}"
        else
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to experiment.name,
                     canvas_experiment_path(experiment)}"
        end
      when 'tsk'
        my_module = MyModule.find_by_id(match[3].base62_decode)
        next unless my_module
        if my_module.archived?
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to my_module.name,
                     module_archive_experiment_path(my_module.experiment)} " \
          "#{t'atwho.res.archived'}"
        else
          "<span class='sa-type'>#{sanitize(match[2])}</span> " \
          "#{link_to my_module.name,
                     protocols_my_module_path(my_module)}"
        end
      when 'sam'
        sample = Sample.find_by_id(match[3].base62_decode)
        if sample
          "<span class='glyphicon glyphicon-tint'></span> " \
          "#{link_to(sample.name,
                     sample_path(sample.id),
                     class: 'sample-info-link')}"
        else
          "<span class='glyphicon glyphicon-tint'></span> " \
          "#{match[1]} #{t'atwho.res.deleted'}"
        end
      end
    end

    sa_user = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    new_text = new_text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      user = User.find_by_id(match[2].base62_decode)
      if user
        "<span>#{image_tag avatar_path(user, :icon_small)} " \
        "#{user.full_name}</span>"
      end
    end
    new_text
  end
end

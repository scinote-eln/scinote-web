class SmartAnnotation
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper

  attr_writer :current_user, :current_organization, :query

  def initialize(current_user, current_organization, query)
    @current_user = current_user
    @current_organization = current_organization
    @query = query
  end

  def my_modules
    # Search tasks
    res = MyModule
          .search(@current_user, false, @query, 1, @current_organization)
          .limit(Constants::ATWHO_SEARCH_LIMIT)

    modules_list = []
    res.each do |my_module_res|
      my_mod = {}
      my_mod['id'] = my_module_res.id.base62_encode
      my_mod['name'] = sanitize(my_module_res.name)
      my_mod['archived'] = my_module_res.archived
      my_mod['experimentName'] = truncate(
        sanitize(my_module_res.experiment.name,
                 length: Constants::NAME_TRUNCATION_LENGTH)
      )
      my_mod['projectName'] = truncate(
        sanitize(my_module_res.experiment.project.name,
                 length: Constants::NAME_TRUNCATION_LENGTH)
      )
      my_mod['type'] = 'tsk'

      modules_list << my_mod
    end
    modules_list
  end

  def projects
    # Search projects
    res = Project
          .search(@current_user, false, @query, 1, @current_organization)
          .limit(Constants::ATWHO_SEARCH_LIMIT)

    projects_list = []
    res.each do |project_res|
      prj = {}
      prj['id'] = project_res.id.base62_encode
      prj['name'] = sanitize(project_res.name)
      prj['type'] = 'prj'
      projects_list << prj
    end
    projects_list
  end

  def experiments
    # Search experiments
    res = Experiment
          .search(@current_user, false, @query, 1, @current_organization)
          .limit(Constants::ATWHO_SEARCH_LIMIT)

    experiments_list = []
    res.each do |experiment_res|
      exp = {}
      exp['id'] = experiment_res.id.base62_encode
      exp['name'] = sanitize(experiment_res.name)
      exp['type'] = 'exp'
      exp['projectName'] = truncate(
        sanitize(experiment_res.project.name,
                 length: Constants::NAME_TRUNCATION_LENGTH)
      )
      experiments_list << exp
    end
    experiments_list
  end

  def samples
    # Search samples
    res = Sample
          .search(@current_user, false, @query, 1, @current_organization)
          .limit(Constants::ATWHO_SEARCH_LIMIT)

    samples_list = []
    res.each do |sample_res|
      sam = {}
      sam['id'] = sample_res.id.base62_encode
      sam['name'] = sanitize(sample_res.name)
      sam['description'] = "#{I18n.t('Added')} #{I18n.l(
        sample_res.created_at, format: :full_date
      )} #{I18n.t('by')} #{truncate(
        sanitize(sample_res.user.full_name,
                 length: Constants::NAME_TRUNCATION_LENGTH)
      )}"
      sam['type'] = 'sam'
      samples_list << sam
    end
    samples_list
  end
end

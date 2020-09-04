class SmartAnnotation
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper

  attr_writer :current_user, :current_team, :query

  def initialize(current_user, current_team, query)
    @current_user = current_user
    @current_team = current_team
    @query = query
  end

  def my_modules
    # Search tasks
    task_ids = MyModule.search(@current_user, false, @query, 1, @current_team)
                .limit(Constants::ATWHO_SEARCH_LIMIT).pluck(:id)
    MyModule.where(id: task_ids)
  end

  def projects
    # Search projects
    Project.search(@current_user, false, @query, 1, @current_team)
           .limit(Constants::ATWHO_SEARCH_LIMIT)
  end

  def experiments
    # Search experiments
    Experiment.search(@current_user, false, @query, 1, @current_team)
              .limit(Constants::ATWHO_SEARCH_LIMIT)
  end

  def samples
    # Search samples
    res = Sample
          .search(@current_user, false, @query, 1, @current_team)
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

  def repository_rows(repository)
    res = RepositoryRow
          .active
          .where(repository: repository)
          .where_attributes_like('name', @query, at_search: true)
          .limit(Constants::ATWHO_SEARCH_LIMIT)
    rep_items_list = []
    splitted_name = repository.name.gsub(/[^0-9a-z ]/i, '').split
    repository_tag =
      case splitted_name.length
      when 1
        splitted_name[0][0..2]
      when 2
        if splitted_name[0].length == 1
          splitted_name[0][0] + splitted_name[1][0..1]
        else
          splitted_name[0][0..1] + splitted_name[1][0]
        end
      else
        splitted_name[0][0] + splitted_name[1][0] + splitted_name[2][0]
      end
    repository_tag.downcase!
    res.each do |rep_row|
      rep_item = {}
      rep_item[:id] = rep_row.id.base62_encode
      rep_item[:name] = sanitize(rep_row.name)
      rep_item[:repository_tag] = repository_tag
      rep_items_list << rep_item
    end
    rep_items_list
  end
end

module SearchHelper
  def experiments_results(tag)
    experiments = []
    tag.my_modules.each do |mod|
      experiments << mod.experiment
    end
    experiments.uniq
  end

  def route_to_other_team(path, search_team, text, html = {})
    if search_team != current_team
      link_to text,
              path,
              html.merge(
                data: { turbolinks: false,
                        confirm: t('users.settings.changed_team_in_search',
                                   team: search_team.name) }
              )
    else
      link_to text, path, html.merge(data: { turbolinks: false })
    end
  end

  def route_to_other_team_btn(path, search_team, text)
    if search_team != current_team
      link_to text,
              path,
              class: 'btn btn-primary',
              data: { confirm: t('users.settings.changed_team_in_search',
                                 team: search_team.name) }
    else
      link_to text, path, class: 'btn btn-primary'
    end
  end
end

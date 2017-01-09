module SearchHelper
  def experiments_results(tag)
    experiments = []
    tag.my_modules.each do |mod|
      experiments << mod.experiment
    end
    experiments.uniq
  end

  def route_to_other_org(path, search_org, text)
    if search_org != current_organization
      link_to text,
              path,
              data: { confirm: t('users.settings.changed_org_in_search',
                                 team: search_org.name) }
    else
      link_to text, path
    end
  end

  def route_to_other_org_btn(path, search_org, text)
    if search_org != current_organization
      link_to text,
              path,
              class: 'btn btn-primary',
              data: { confirm: t('users.settings.changed_org_in_search',
                                 team: search_org.name) }
    else
      link_to text, path, class: 'btn btn-primary'
    end
  end
end

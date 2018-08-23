module SearchHelper
  def experiments_results(tag)
    experiments = []
    tag.my_modules.each do |mod|
      experiments << mod.experiment
    end
    experiments.uniq
  end

  def user_current_team_change(new_team_id)
    team_id = new_team_id.to_i
    if @user.teams_ids.include?(team_id)
      @user.current_team_id = team_id
      @changed_team = Team.find_by_id(@user.current_team_id)
      if @user.save
        flash[:success] = t('users.settings.changed_team_flash',
                            team: @changed_team.name)
        redirect_to root_path
        return
      end
    end
    flash[:alert] = t('users.settings.changed_team_error_flash')
    redirect_back(fallback_location: root_path)
  end

  def route_to_other_team(path, search_team, text)
    if search_team != current_team
      user_current_team_change(search_team.id) unless path.include?('?team=')
      link_to text,
              path,
              data: {
                no_turbolink: true,
                confirm: t(
                  'users.settings.changed_team_in_search',
                  team: search_team.name
                )
              }
    else
      link_to text, path, data: { no_turbolink: true }
    end
  end

  def route_to_other_team_btn(path, search_team, text)
    if search_team != current_team

      link_to text,
              path,
              class: 'btn btn-success',
              data: {
                no_turbolink: true,
                confirm: t(
                  'users.settings.changed_team_in_search',
                  team: search_team.name
                )
              }
    else
      link_to text, path, class: 'btn btn-success', data: { no_turbolink: true }
    end
  end
end

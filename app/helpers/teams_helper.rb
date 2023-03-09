module TeamsHelper
  # resets the current team if needed
  def current_team_switch(team)
    if team != current_team && current_user.member_of_team?(team)
      current_user.current_team_id = team.id
      current_user.save
      update_current_team
    end
  end

  def truncate_team_name(name, len = Constants::NAME_TRUNCATION_LENGTH)
    if name.length > len
      sanitize_input("<div class='modal-tooltip'>#{truncate(name, length: len)}
		    <span class='modal-tooltiptext'>#{name}</span>
      </div>")
    else
      name
    end
  end

  def switch_team_with_param
    current_team_switch(current_user.teams.find_by(id: params[:team])) if params[:team]
  end
end

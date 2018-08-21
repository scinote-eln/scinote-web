class TeamsDatatable < CustomDatatable
  include InputSanitizeHelper

  def_delegator :@view, :link_to
  def_delegator :@view, :team_path
  def_delegator :@view, :leave_user_team_html_path

  MEMEBERS_SORT_COL = 'members'.freeze

  def initialize(view, user)
    super(view)
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'Team.name',
      'UserTeam.role',
      MEMEBERS_SORT_COL
    ]
  end

  private

  # Returns json of current samples (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId': record.id,
        '0': if record.admin?
               link_to(escape_input(record.team.name), team_path(record.team))
             else
               escape_input(record.team.name)
             end,
        '1': escape_input(record.role_str),
        '2': if record.guest?
               I18n.t('users.settings.teams.index.na')
             else
               record.team.users.count
             end,
        '3': leave_team_button(record)
      }
    end
  end

  # Overwrite default pagination method as here
  # we need to be able work also with arrays
  def paginate_records(records)
    records.to_a.drop(offset).first(per_page)
  end

  def load_paginator
    self
  end

  # Overwrite default sort method to handle custom members column
  # which is calculated in code and not present in DB
  def sort_records(records)
    if sort_column(order_params) == MEMEBERS_SORT_COL
      records = records.sort_by(&proc { |ut| ut.team.users.count })
      if order_params['dir'] == 'asc'
        return records
      elsif order_params['dir'] == 'desc'
        return records.reverse
      end
    else
      super(records)
    end
  end

  # If user is last admin of team, don't allow
  # him/her to leave team
  def leave_team_button(user_team)
    button = "<span class=\"fas fa-sign-out-alt\"></span>
              <span class=\"hidden-xs\">
                #{I18n.t('users.settings.teams.index.leave')}
              </span>"
    team = user_team.team
    if user_team.admin? && team.user_teams.where(role: 2).count <= 1
      button.prepend('<div class="btn btn-default btn-xs"
                      type="button" disabled="disabled">')
      button << '</div>'
    else
      button = link_to(
        button.html_safe,
        leave_user_team_html_path(user_team, format: :json),
        remote: true, class: 'btn btn-default btn-xs', type: 'button',
        data: { action: 'leave-user-team' }
      )
    end
    button
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    UserTeam
      .includes(:team)
      .references(:team)
      .where(user: @user)
  end
end

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
      'UserRole.name',
      MEMEBERS_SORT_COL
    ]
  end

  private

  # Returns json of current items (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId': record.id,
        '0': if current_user_team_role(record)&.owner?
               link_to(escape_input(record.name), team_path(record))
             else
               escape_input(record.name)
             end,
        '1': escape_input(current_user_team_role(record)&.name),
        '2': record.users.count,
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
      records = records.sort_by(&proc { |team| team.users.count })
      if order_params['dir'] == 'asc'
        records
      elsif order_params['dir'] == 'desc'
        records.reverse
      end
    elsif sort_column(order_params) == 'user_roles.name'
      records_with_role = records.joins(user_assignments: :user)
                                 .where(user_assignments: { user: @user })
                                 .sort_by(&proc { |team| current_user_team_role(team)&.name })
      records_with_no_role =
        records.joins("LEFT OUTER JOIN user_assignments AS current_user_assignments "\
                      "ON current_user_assignments.assignable_type = 'Team' "\
                      "AND current_user_assignments.assignable_id = teams.id "\
                      "AND current_user_assignments.user_id = #{@user.id}")
               .where(current_user_assignments: { id: nil })
      records = records_with_no_role + records_with_role
      if order_params['dir'] == 'asc'
        records
      else
        records.reverse
      end
    else
      super(records)
    end
  end

  # If user is last admin of team, don't allow
  # him/her to leave team
  def leave_team_button(record)
    button = "<span class=\"sn-icon sn-icon-sign-out\"></span>
              <span class=\"hidden-xs\">
                #{I18n.t('users.settings.teams.index.leave')}
              </span>"
    owner_role = UserRole.find_by(name: UserRole.public_send('owner_role').name)
    if current_user_team_role(record)&.owner? && record.user_assignments.where(user_role: owner_role).none?
      button.prepend('<div class="btn btn-secondary btn-xs"
                      type="button" disabled="disabled">')
      button << '</div>'
    else
      button = link_to(
        button.html_safe,
        leave_user_team_html_path(current_user_team_assignment(record), format: :json, leave: true),
        remote: true, class: 'btn btn-secondary btn-xs', type: 'button',
        data: { action: 'leave-user-team' }
      )
    end
    button
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    @user.teams
         .preload(user_assignments: %i(user user_role))
         .distinct
  end

  def current_user_team_assignment(team)
    team.user_assignments.find { |ua| ua.user == @user }
  end

  def current_user_team_role(team)
    current_user_team_assignment(team)&.user_role
  end
end

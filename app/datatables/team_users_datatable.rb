# frozen_string_literal: true

class TeamUsersDatatable < CustomDatatable
  include InputSanitizeHelper
  include ActiveRecord::Sanitization::ClassMethods

  def_delegator :@view, :link_to
  def_delegator :@view, :update_user_team_path
  def_delegator :@view, :destroy_user_team_html_path

  def initialize(view, team, user)
    super(view)
    @team = team
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'User.full_name',
      'User.email',
      'UserRole.name',
      'UserAssignment.created_at',
      'User.status'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      'User.full_name',
      'User.email',
      'UserAssignment.created_at'
    ]
  end

  # A hack that overrides the new_search_contition method default behavior of
  # the ajax-datatables-rails gem now the method checks if the column is the
  # created_at and generate a custom SQL to parse it back to the caller method
  def new_search_condition(column, value)
    model, column = column.split('.')
    model = model.constantize
    if column == 'created_at'
      casted_column = ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [Arel.sql(
          "to_char( user_assignments.created_at, '#{formated_date}' ) AS VARCHAR"
        )]
      )
    else
      casted_column = ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [model.arel_table[column.to_sym].as(typecast)]
      )
    end
    casted_column.matches("%#{sanitize_sql_like(value)}%")
  end

  private

  # Returns json of current items (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId': record.id,
        '0': escape_input(record.user.full_name),
        '1': escape_input(record.user.email),
        '2': record.user_role.name,
        '3': I18n.l(record.created_at, format: :full_date),
        '4': record.user.active_status_str,
        '5': @view.controller.render_to_string(
          partial: 'users/settings/teams/user_dropdown',
          locals: {
            user_assignment: record,
            update_role_path: update_user_team_path(record, format: :json),
            destroy_uo_link: link_to(
              I18n.t('users.settings.teams.edit.user_dropdown.remove_label'),
              destroy_user_team_html_path(record, format: :json),
              remote: true,
              data: { action: 'destroy-user-team' }
            ),
            user: @user
          },
          formats: :html
        )
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

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    @team.user_assignments.joins(:user)
  end

  def sort_records(records)
    case sort_column(order_params)
    when 'users.status'
      records = records.sort_by { |record| record.user.active_status_str }
      order_params['dir'] == 'asc' ? records : records.reverse
    when 'user_roles.name'
      records = records.sort_by { |record| record.user_role.name }
      order_params['dir'] == 'asc' ? records : records.reverse
    else
      super(records)
    end
  end
end

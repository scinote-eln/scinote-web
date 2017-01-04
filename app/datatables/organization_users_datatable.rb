class OrganizationUsersDatatable < AjaxDatatablesRails::Base
  include InputSanitizeHelper

  def_delegator :@view, :link_to
  def_delegator :@view, :update_user_organization_path
  def_delegator :@view, :destroy_user_organization_html_path

  def initialize(view, org, user)
    super(view)
    @org = org
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      "User.full_name",
      "User.email",
      "UserOrganization.created_at",
      "User.confirmed_at",
      "UserOrganization.role"
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      "User.full_name",
      "User.email",
      "UserOrganization.created_at"
    ]
  end

  # A hack that overrides the new_search_contition method default behavior of the ajax-datatables-rails gem
  # now the method checks if the column is the created_at and generate a custom SQL to parse
  # it back to the caller method
  def new_search_condition(column, value)
    model, column = column.split('.')
    model = model.constantize
    formated_date = (I18n.t 'time.formats.datatables_date').gsub!(/^\"|\"?$/, '')
    if column == 'created_at'
      casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
                        [ Arel.sql("to_char( users.created_at, '#{ formated_date }' ) AS VARCHAR") ] )
    else
      casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
                        [model.arel_table[column.to_sym].as(typecast)])
    end
    casted_column.matches("%#{value}%")
  end
  private

  # Returns json of current samples (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId': record.id,
        '0': sanitize_input(record.user.full_name),
        '1': sanitize_input(record.user.email),
        '2': I18n.l(record.created_at, format: :full),
        '3': record.user.active_status_str,
        '4': record.role_str,
        '5': ApplicationController.new.render_to_string(
          partial: "users/settings/organizations/user_dropdown.html.erb",
          locals: {
            user_organization: record,
            update_role_path: update_user_organization_path(record, format: :json),
            destroy_uo_link: link_to(
              I18n.t("users.settings.organizations.edit.user_dropdown.remove_label"),
              destroy_user_organization_html_path(record, format: :json),
              remote: true,
              data: { action: "destroy-user-organization" }
            ),
            user: @user
          }
        )
      }
    end
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    UserOrganization
    .includes(:user)
    .references(:user)
    .where(organization: @org)
    .distinct
  end

end

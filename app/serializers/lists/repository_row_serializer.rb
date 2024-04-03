# frozen_string_literal: true

class Lists::RepositoryRowSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :name, :code

  attribute :assigned do
    {
      tasks: object.assigned_my_modules_count,
      experiments: object.assigned_experiments_count,
      projects: object.assigned_projects_count,
      task_list_url: assigned_task_list_repository_repository_row_path(object.repository, object)
    }
  end

  attribute :connections do
    "#{object.parent_connections_count || 0} / #{object.child_connections_count || 0}"
  end

  attribute :created_at do
    I18n.l(object.created_at, format: :full)
  end

  attribute :created_by do
    object.created_by.full_name
  end

  attribute :archived_on do
    object.archived_on ? I18n.l(object.archived_on, format: :full) : ''
  end

  attribute :archived_by do
    object.archived_by&.full_name
  end

  attribute :urls do
    urls_list = {}
    if can_manage_repository_rows?(object.repository)
      urls_list[:update] = update_cell_repository_repository_row_path(object.repository, object)
    end
    urls_list
  end

  def attributes(_options = {})
    data = super
    repository = object.repository
    team = repository.team
    reminders_enabled = Repository.reminders_enabled?
    has_stock_management = repository.has_stock_management?
    stock_managable = has_stock_management &&
                      can_manage_repository_stock?(repository)
    custom_cells = object.repository_cells.filter { |cell| cell.value_type != 'RepositoryStockValue' }

    custom_cells.each do |cell|
      serializer_class = "RepositoryDatatable::#{cell.repository_column.data_type}Serializer".constantize
      data["col_#{cell.repository_column.id}"] = serializer_class.new(
        cell.value,
        scope: {
          team: team,
          user: current_user,
          column: cell.repository_column,
          repository: repository,
          options: {reminders_enabled: reminders_enabled}
        }
      ).serializable_hash
    end

    if has_stock_management
      stock_cell = object.repository_cells.find { |cell| cell.value_type == 'RepositoryStockValue' }
      stock_column = repository.repository_columns.find_by(data_type: 'RepositoryStockValue')
      col_key = 'col_' + stock_column.id.to_s
      data[col_key] = if stock_cell.present?
                        RepositoryDatatable::RepositoryStockValueSerializer.new(
                          stock_cell.value,
                          scope: {
                            team: team,
                            user: current_user,
                            column: stock_cell.repository_column,
                            repository: repository,
                            options: {reminders_enabled: reminders_enabled}
                          }
                        ).serializable_hash
                      else
                        { stock_url: new_repository_stock_repository_repository_row_url(repository, object) }
                      end
      data[col_key][:stock_managable] = stock_managable && object.active?
      data[col_key][:display_warnings] = display_stock_warnings?(repository)
      data[col_key][:stock_status] = stock_cell&.value&.status
      data[col_key][:value_type] = 'RepositoryStockValue'
    end

    data
  end

  private

  def display_stock_warnings?(repository)
    !repository.is_a?(RepositorySnapshot)
  end

  def stock_consumption_managable?(record, repository, my_module)
    return false unless my_module
    return false if repository.archived? || record.archived?

    true
  end
end

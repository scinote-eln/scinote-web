# frozen_string_literal: true

module GlobalSearch
  class AssetSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include FileIconsHelper
    attributes :id, :file_name, :icon, :created_at, :updated_at, :team, :parent, :experiment, :repository

    def file_name
      object.render_file_name
    end

    def icon
      file_fa_icon_class(object)
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def team
      {
        name: object.team.name,
        url: dashboard_path(team: object.team)
      }
    end

    def experiment
      return { name: '' } unless object.my_module

      archived = object.my_module.experiment.archived_branch?
      {
        name: object.my_module.experiment.name,
        url: my_modules_experiment_path(id: object.my_module.experiment.id, view_mode: view_mode(archived)),
        archived: archived
      }
    end

    def repository
      parent = object.parent

      return { name: '' } unless parent.is_a?(RepositoryCell)

      archived = parent.repository_row.archived?

      {
        name: parent.repository_row.repository.name,
        url: repository_path(id: parent.repository_row.repository_id, archived: archived),
        archived: archived
      }
    end

    def parent
      parent = object.parent
      if parent.is_a?(Result) && object.my_module
        parent_type = 'task'
        parent_name = object.my_module.name
        parent_archived = parent.my_module.archived_branch?
        parent_url = my_module_results_path(my_module_id: object.my_module.id, view_mode: view_mode(parent.archived?))
      elsif parent.is_a?(Step) && object.my_module
        parent_type = 'task'
        parent_name = object.my_module.name
        parent_archived = object.my_module.archived_branch?
        parent_url = protocols_my_module_path(object.my_module.id,
                                              view_mode: view_mode(parent_archived))
      elsif parent.is_a?(Step)
        parent_type = 'protocol_template'
        parent_name = parent.protocol.name || I18n.t('search.index.untitled_protocol')
        parent_url = protocol_path(parent.protocol_id)
        parent_archived = parent.protocol.archived?
      elsif parent.is_a?(RepositoryCell)
        parent_type = 'inventory_item'
        parent_name = parent.repository_row.name
        parent_archived = parent.repository_row.archived?

        params = {
          id: parent.repository_row.repository_id,
          landing_page: true,
          row_id: parent.repository_row.id
        }
        params[:archived] = true if parent_archived
        parent_url = repository_path(params)
      end

      { name: parent_name, url: parent_url, type: parent_type, archived: parent_archived }
    end

    private

    def view_mode(archived)
      archived ? 'archived' : 'active'
    end
  end
end

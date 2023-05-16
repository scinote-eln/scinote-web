# frozen_string_literal: true

module Toolbars
  class LabelTemplatesService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, label_template_ids: [])
      @current_user = current_user
      @label_templates = LabelTemplate.where(id: label_template_ids)

      @single = @label_templates.length == 1
    end

    def actions
      return [] if @label_templates.none?

      [
        edit_action,
        duplicate_action,
        set_as_default_action,
        delete_action
      ].compact
    end

    private

    def any_fluics?
      @label_templates.any? { |lt| lt.type == 'FluicsLabelTemplate' }
    end

    def edit_action
      return unless @single

      {
        name: 'edit',
        label: I18n.t('label_templates.index.toolbar.edit'),
        icon: 'fas fa-pencil-alt',
        path: label_template_path(@label_templates.first),
        type: :link
      }
    end

    def set_as_default_action
      return unless @single

      return unless can_manage_label_templates?(current_user.current_team)

      return if @label_templates.first.default

      {
        name: 'set_as_default',
        label: I18n.t("label_templates.index.toolbar.set_#{@label_templates.first.type}_default"),
        icon: 'fas fa-thumbtack',
        button_id: 'setZplDefaultLabelTemplate',
        type: :legacy
      }
    end

    def duplicate_action
      return if any_fluics?

      return unless can_manage_label_templates?(current_user.current_team)

      {
        name: 'duplicate',
        label: I18n.t('label_templates.index.toolbar.duplicate'),
        icon: 'fas fa-copy',
        button_id: 'duplicateLabelTemplate',
        path: duplicate_label_templates_path,
        type: :legacy
      }
    end

    def delete_action
      return if any_fluics?

      return unless can_manage_label_templates?(current_user.current_team)

      return unless @label_templates.none?(&:default)

      {
        name: 'delete',
        label: I18n.t('label_templates.index.toolbar.delete'),
        icon: 'fas fa-trash',
        button_id: 'deleteLabelTemplate',
        type: :legacy
      }
    end
  end
end

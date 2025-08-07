# frozen_string_literal: true

module Toolbars
  class FormsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(forms, current_user)
      @forms = forms
      @current_user = current_user

      @single = @forms.length == 1
    end

    def actions
      return [] if @forms.none?

      [
        access_action,
        duplicate_action,
        archive_action,
        restore_action,
        export_action
      ].compact
    end

    private

    def access_action
      return unless @single

      {
        name: 'access',
        label: I18n.t('forms.index.toolbar.access'),
        icon: 'sn-icon sn-icon-project-member-access',
        type: :emit
      }
    end

    def archive_action
      return unless @forms.all? { |form| can_archive_form?(form) }

      {
        name: 'archive',
        label: I18n.t('forms.index.toolbar.archive'),
        icon: 'sn-icon sn-icon-archive',
        path: archive_forms_path(form_ids: @forms.pluck(:id)),
        type: :emit
      }
    end

    def restore_action
      return unless @forms.all? { |form| can_restore_form?(form) }

      {
        name: 'restore',
        label: I18n.t('forms.index.toolbar.restore'),
        icon: 'sn-icon sn-icon-restore',
        path: restore_forms_path(form_ids: @forms.pluck(:id)),
        type: :emit
      }
    end

    def duplicate_action
      return unless @single

      return unless can_manage_form?(@forms.first)

      {
        name: 'duplicate',
        label: I18n.t('forms.index.toolbar.duplicate'),
        icon: 'sn-icon sn-icon-duplicate',
        path: duplicate_form_path(@forms.first),
        type: :emit
      }
    end

    def export_action
      return unless @single

      return unless @forms.first.published?

      return unless can_read_form?(@forms.first)

      {
        name: 'export',
        label: I18n.t('protocols.index.toolbar.export'),
        icon: 'sn-icon sn-icon-export',
        path: export_form_responses_form_path(@forms.first),
        type: :emit
      }
    end
  end
end

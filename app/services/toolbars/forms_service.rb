# frozen_string_literal: true

module Toolbars
  class FormsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, form_ids: [])
      @current_user = current_user
      @forms = Form.where(id: forms_ids)

      @single = @forms.length == 1
    end

    def actions
      return [] if @forms.none?

      [].compact
    end

    private

  end
end

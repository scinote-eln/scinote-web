# frozen_string_literal: true

module Reports
  class ProjectMembersInputComponent < TemplateValueComponent
    def initialize(report:, name:, label:, placeholder: nil, editing: true, displayed_field: :full_name)
      super(report: report, name: name, label: label, placeholder: placeholder, editing: editing)
      @project_members = report.project&.users
      @displayed_field = displayed_field
    end
  end
end

# frozen_string_literal: true

module Reports
  class TeamMemberInputComponent < TemplateValueComponent
    def initialize(report:, name:, label:, placeholder: nil, editing: true, team:)
      super(report: report, name: name, label: label, placeholder: placeholder, editing: editing)
      @team_members = team.users
    end
  end
end

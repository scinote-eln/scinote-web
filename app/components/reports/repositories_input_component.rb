# frozen_string_literal: true

module Reports
  class RepositoriesInputComponent < TemplateValueComponent
    def initialize(report:, name:, label:, placeholder: nil, editing: true, displayed_field: :name, user: nil)
      super(report: report, name: name, label: label, placeholder: placeholder, editing: editing)
      live_repositories = Repository.readable_by_user(user, report.team).sort_by { |r| r.name.downcase }
      snapshots_of_deleted = RepositorySnapshot.left_outer_joins(:original_repository)
                                               .where(team: report.team)
                                               .where.not(original_repository: report.team.repositories)
                                               .select('DISTINCT ON ("repositories"."parent_id") "repositories".*')
                                               .sort_by { |r| r.name.downcase }
      @repositories = live_repositories + snapshots_of_deleted
      @displayed_field = displayed_field
    end
  end
end

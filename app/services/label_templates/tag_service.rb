# frozen_string_literal: true

module LabelTemplates
  class TagService
    DEFAULT_COLUMNS = [
      { key: I18n.t('label_templates.default_columns.item_id'), tag: '{{ITEM_ID}}' },
      { key: I18n.t('label_templates.default_columns.name'), tag: '{{NAME}}' },
      { key: I18n.t('label_templates.default_columns.added_on'), tag: '{{ADDED_ON}}' },
      { key: I18n.t('label_templates.default_columns.added_by'), tag: '{{ADDED_BY}}' }
    ].freeze

    def initialize(team)
      @team = team
    end

    def tags
      {
        default: DEFAULT_COLUMNS,
        common: repository_tags.pluck(:tags).reduce(:&),
        repositories: repository_tags
      }
    end

    private

    def repository_tags
      @repository_tags ||=
        Repository.includes(:repository_columns).active.where(team: @team).map do |repository|
          {
            repository_id: repository.id,
            repository_name: repository.name,
            tags: repository.repository_columns.pluck(:name).map do |name|
              {
                key: name,
                tag: "{{c_#{name}}}"
              }
            end
          }
        end
    end
  end
end

# frozen_string_literal: true

module LabelTemplates
  class TagService
    DEFAULT_COLUMNS = [
      { key: 'item_id', tag: '{{ITEM_ID}}' },
      { key: 'name', tag: '{{NAME}}' },
      { key: 'added_on', tag: '{{ADDED_ON}}' },
      { key: 'added_by', tag: '{{ADDED_BY}}' }
    ].freeze

    def initialize(team, label_template)
      @team = team
      @label_template = label_template
    end

    def tags
      custom_common_columns = repository_tags.present? ? repository_tags.pluck(:tags).reduce(:&) : []
      {
        default: DEFAULT_COLUMNS,
        common: common_columns + custom_common_columns,
        repositories: repository_tags
      }
    end

    private

    def common_columns
      @common_columns ||= []
    end

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

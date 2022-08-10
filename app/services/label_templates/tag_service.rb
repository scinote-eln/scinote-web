# frozen_string_literal: true

module LabelTemplates
  class TagService
    DEFAULT_COLUMNS = [
      { key: :item_id, tag: '{{ITEM_ID}}' },
      { key: :added_by, tag: '{{ADDED_BY}}' },
      { key: :added_on, tag: '{{ADDED_ON}}' },
      { key: :name, tag: '{{NAME}}' }
    ].freeze

    def initialize(team)
      @team = team
    end

    def tags
      {
        default: DEFAULT_COLUMNS,
        common: repository_tags.pluck(:tags).reduce(:&),
        repository: repository_tags
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
                tag: "{{COLUMN_[#{name}]}}"
              }
            end
          }
        end
    end
  end
end

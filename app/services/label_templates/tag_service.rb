# frozen_string_literal: true

module LabelTemplates
  class TagService
    DEFAULT_COLUMNS = [
      { key: 'Item ID', tag: '{{ITEM_ID}}' },
      { key: 'Name', tag: '{{NAME}}' },
      { key: 'Added on', tag: '{{ADDED_ON}}' },
      { key: 'Added by', tag: '{{ADDED_BY}}' }
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
                tag: "{{COLUMN_[#{name}]}}"
              }
            end
          }
        end
    end
  end
end

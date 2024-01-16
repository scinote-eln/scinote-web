# frozen_string_literal: true

module RepositoryActions
  class DuplicateRows
    attr_reader :number_of_duplicated_items
    def initialize(user, repository, rows_ids = [])
      @user                       = user
      @repository                 = repository
      @rows_to_duplicate          = rows_ids
      @number_of_duplicated_items = 0
    end

    def call
      @rows_to_duplicate.each do |row_id|
        duplicate_row(row_id)
      end
    end

    private

    def duplicate_row(id)
      RepositoryRow.transaction do
        row = @repository.repository_rows.find_by(id: id)
        return unless row

        new_row = RepositoryRow.create!(
          row.attributes.merge(new_row_attributes(row.name, @user.id))
        )

        row.repository_cells.each do |cell|
          RepositoryActions::DuplicateCell.new(cell, new_row, @user).call
        end

        @number_of_duplicated_items += 1

        Activities::CreateActivityService
          .call(activity_type: :copy_inventory_item,
                owner: @user,
                subject: @repository,
                team: @repository.team,
                message_items: { repository_row_new: new_row.id, repository_row_original: row.id })
      end
    end

    def new_row_attributes(name, user_id)
      timestamp = DateTime.now
      { id: nil,
        name: "#{name} (1)",
        created_by_id: user_id,
        created_at: timestamp,
        updated_at: timestamp,
        parent_connections_count: 0,
        child_connections_count: 0 }
    end
  end
end

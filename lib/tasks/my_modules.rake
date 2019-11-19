# frozen_string_literal: true

# On production around 2k records for repair, for production DB it tooked cca 1 min

# rubocop:disable Metrics/BlockLength
namespace :my_modules do
  desc 'Find new positions on canvas for already taken coordiantes'
  task fix_positions: :environment do
    query = MyModule.select('COUNT(*) as duplicates', :x, :y, :experiment_id)
                    .where(archived: false)
                    .group(:x, :y, :experiment_id)
                    .having('COUNT(my_modules.id)>1')

    Rails.logger.info '*********************************************************************************'
    Rails.logger.info "You have to relocate #{query.sum { |a| a.duplicates - 1 }} tasks"
    Rails.logger.info '*********************************************************************************'

    query.each do |row|
      tasks_to_update = MyModule.where(experiment_id: row.experiment, x: row.x, y: row.y, archived: false)
                                .order(created_at: :asc)
                                .offset(1)

      tasks_to_update.find_each do |task|
        coordinates = task.get_new_position
        task.attributes = coordinates
        begin
          task.save!
          Rails.logger.info "Relocated task with ID #{task.id}"
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "Unable to save task with ID #{task.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info '*********************************************************************************'
    Rails.logger.info "You have #{query.reload.sum { |a| a.duplicates - 1 }} tasks on invalid positions"
    Rails.logger.info '*********************************************************************************'
  end
end
# rubocop:enable Metrics/BlockLength

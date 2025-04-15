# frozen_string_literal: true

class UpdateNotStartedTaskStatusAndStartDates < ActiveRecord::Migration[7.0]
  NOT_STARTED_STATUS = 'Not started'
  IN_PROGRESS_STATUS = 'In progress'

  def up
    not_started_status = MyModuleStatus.find_by(name: NOT_STARTED_STATUS)
    MyModuleStatusImplications::NotStarted.create!(my_module_status: not_started_status)
    in_progress_status = MyModuleStatus.find_by(name: IN_PROGRESS_STATUS)
    MyModuleStatusConsequences::Started.create!(my_module_status: in_progress_status)

    started_at = DateTime.now
    Experiment.distinct
              .joins(my_modules: :my_module_status)
              .where(started_at: nil)
              .where.not(my_modules: { my_module_statuses: { name: NOT_STARTED_STATUS } })
              .update_all(started_at: started_at)
    Project.distinct
           .joins(experiments: { my_modules: :my_module_status })
           .where(started_at: nil)
           .where.not(experiments: { my_modules: { my_module_statuses: { name: NOT_STARTED_STATUS } } })
           .update_all(started_at: started_at)
  end

  def down
    Project.where.not(started_at: nil).update_all(started_at: nil)
    Experiment.where.not(started_at: nil).update_all(started_at: nil)
  end
end

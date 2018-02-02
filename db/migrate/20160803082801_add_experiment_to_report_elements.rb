class AddExperimentToReportElements < ActiveRecord::Migration[4.2]
  def up
    add_column :report_elements, :experiment_id, :integer
    add_foreign_key :report_elements, :experiments
    add_index :report_elements, :experiment_id

    Project.find_each do |project|
      experiment = project.experiments.first

      next unless experiment && project.reports.count > 0
      project.reports.each do |report|
        project_element = report.report_elements.where(type_of: 0).first
        module_elements = report.report_elements.where(type_of: 1)

        next unless project_element
        experiment_element = report.report_elements.create(
          type_of: :experiment,
          experiment: experiment,
          position: 0
        )

        next unless module_elements.count > 0
        module_elements.each do |element|
          element.parent_id = experiment_element.id
          element.save!
        end
      end
    end
  end

  def down
    Project.find_each do |project|
      next unless project.reports.count > 0
      project.reports.each do |report|
        experiment_elements = report.report_elements.where(type_of: 15)
        module_elements = report.report_elements.where(type_of: 1)

        next unless module_elements.count > 0
        module_elements.each do |element|
          element.parent_id = nil
          element.save!
        end
        experiment_elements.destroy_all
      end
    end

    remove_index :report_elements, :experiment_id
    remove_foreign_key :report_elements, :experiments
    remove_column :report_elements, :experiment_id
  end
end

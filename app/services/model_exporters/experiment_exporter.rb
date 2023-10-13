# frozen_string_literal: true

module ModelExporters
  class ExperimentExporter < ModelExporter
    def initialize(experiment_id)
      @include_archived = true
      super()
      @experiment = Experiment.find(experiment_id)
    end

    def export_template_to_dir
      @asset_counter = 0
      @include_archived = false
      @experiment.transaction do
        @experiment.uuid ||= SecureRandom.uuid
        @dir_to_export = FileUtils.mkdir_p(
          File.join("tmp/experiment_#{@experiment.id}" \
                    "_export_#{Time.now.to_i}")
        ).first

        # Writing JSON file with experiment structure
        File.write(
          File.join(@dir_to_export, 'experiment.json'),
          JSON.pretty_generate(experiment[0].as_json)
        )
        # Copying assets
        assets_dir = File.join(@dir_to_export, 'assets')
        copy_files(@assets_to_copy, :file, assets_dir) do
          @asset_counter += 1
        end
        puts "Exported assets: #{@asset_counter}"
        puts 'Done!'
        return @dir_to_export
      end
    end

    def experiment
      if @include_archived
        my_modules = @experiment.my_modules
        my_module_groups = @experiment.my_module_groups
      else
        my_modules = @experiment.my_modules.active
        my_module_groups = @experiment.my_module_groups.without_archived_modules
      end
      return {
        experiment: @experiment,
        user_assignments: @experiment.user_assignments.map do |ua|
          user_assignment(ua)
        end,
        my_modules: my_modules.map { |m| my_module(m) },
        my_module_groups: my_module_groups
      }, @assets_to_copy
    end

    def user_assignment(user_assignment)
      {
        user_id: user_assignment.user_id,
        assigned_by_id: user_assignment.assigned_by_id,
        role_name: user_assignment.user_role.name,
        assigned: user_assignment.assigned
      }
    end

    def my_module(my_module)
      {
        my_module: my_module,
        user_assignments: my_module.user_assignments.map do |ua|
          user_assignment(ua)
        end,
        my_module_status_name: my_module.my_module_status&.name,
        outputs: my_module.outputs,
        my_module_tags: my_module.my_module_tags,
        task_comments: my_module.task_comments,
        my_module_repository_rows: my_module.my_module_repository_rows,
        user_my_modules: my_module.user_my_modules,
        protocols: my_module.protocols.map { |pr| protocol(pr) },
        results: my_module.results.map { |res| result(res) }
      }
    end

    def result(result)
      @assets_to_copy.push(result.assets.to_a) if result.assets.present?
      {
        result: result,
        result_orderable_elements: result.result_orderable_elements.map { |e| result_orderable_element(e) },
        result_comments: result.result_comments,
        result_assets: result.result_assets,
        assets: result.assets.map { |a| assets_data(a) }
      }
    end

    def result_orderable_element(element)
      element_json = element.as_json
      case element.orderable_type
      when 'ResultText'
        element_json['step_text'] = element.orderable.as_json
      when 'ResultTable'
        element_json['table'] = table(element.orderable.table)
      end
      element_json
    end

    def result_assets_data(asset)
      return unless asset&.file&.attached?

      {
        asset: asset,
        asset_blob: asset.file.blob
      }
    end
  end
end

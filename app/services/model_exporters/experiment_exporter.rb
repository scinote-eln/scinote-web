# frozen_string_literal: true

module ModelExporters
  class ExperimentExporter < ModelExporter
    def initialize(experiment_id)
      super()
      @experiment = Experiment.find(experiment_id)
    end

    def export_template_to_dir
      @asset_counter = 0
      @experiment.transaction do
        @experiment.uuid ||= SecureRandom.uuid
        @dir_to_export = FileUtils.mkdir_p(
          File.join("tmp/experiment_#{@experiment.id}" \
                    "_export_#{Time.now.to_i}")
        ).first

        # Writing JSON file with experiment structure
        File.write(
          File.join(@dir_to_export, 'experiment.json'),
          experiment[0].to_json
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
      return {
        experiment: @experiment,
        my_modules: @experiment.my_modules.map { |m| my_module(m) },
        my_module_groups: @experiment.my_module_groups
      }, @assets_to_copy
    end

    def my_module(my_module)
      {
        my_module: my_module,
        outputs: my_module.outputs,
        my_module_tags: my_module.my_module_tags,
        task_comments: my_module.task_comments,
        my_module_repository_rows: my_module.my_module_repository_rows,
        user_my_modules: my_module.user_my_modules,
        protocols: my_module.protocols.map do |pr|
          ProtocolExporter.new(pr.id).protocol
        end,
        results: my_module.results.map { |res| result(res) }
      }
    end

    def result(result)
      @assets_to_copy.push(result.asset) if result.asset.present?
      {
        result: result,
        result_comments: result.result_comments,
        asset: result.asset,
        table: table(result.table),
        result_text: result.result_text
      }
    end
  end
end

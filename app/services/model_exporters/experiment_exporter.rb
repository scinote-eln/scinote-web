# frozen_string_literal: true

module ModelExporters
  class ExperimentExporter < ModelExporter
    def initialize(experiment_id)
      @include_archived = true
      @experiment = Experiment.find_by_id(experiment_id)
      raise StandardError, 'Can not load experiment' unless @experiment

      @assets_to_copy = []
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
      if @include_archived
        my_modules = @experiment.my_modules
        my_module_groups = @experiment.my_module_groups
      else
        my_modules = @experiment.active_my_modules
        my_module_groups = @experiment.active_module_groups
      end
      return {
        experiment: @experiment,
        my_modules: my_modules.map { |m| my_module(m) },
        my_module_groups: my_module_groups
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
        protocols: my_module.protocols.map { |pr| protocol(pr) },
        results: my_module.results.map { |res| result(res) }
      }
    end

    def protocol(protocol)
      {
        protocol: protocol,
        protocol_protocol_keywords: protocol.protocol_protocol_keywords,
        steps: protocol.steps.map { |s| step(s) }
      }
    end

    def step(step)
      @assets_to_copy.push(step.assets.to_a) if step.assets.present?
      {
        step: step,
        checklists: step.checklists.map { |c| checklist(c) },
        step_comments: step.step_comments,
        step_assets: step.step_assets,
        assets: step.assets,
        step_tables: step.step_tables,
        tables: step.tables.map { |t| table(t) }
      }
    end

    def checklist(checklist)
      {
        checklist: checklist,
        checklist_items: checklist.checklist_items
      }
    end

    def table(table)
      return {} if table.nil?

      table_json = table.as_json(except: %i(contents data_vector))
      table_json['contents'] = Base64.encode64(table.contents)
      table_json['data_vector'] = Base64.encode64(table.data_vector)
      table_json
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

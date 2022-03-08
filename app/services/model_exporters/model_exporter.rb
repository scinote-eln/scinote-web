# frozen_string_literal: true

require 'fileutils'

module ModelExporters
  class ModelExporter
    attr_accessor :assets_to_copy
    attr_accessor :tiny_mce_assets_to_copy

    def initialize
      @assets_to_copy = []
      @tiny_mce_assets_to_copy = []
    end

    def copy_files(assets, attachment_name, dir_name)
      assets.flatten.each do |a|
        next unless a.public_send(attachment_name).present?

        unless a.public_send(attachment_name).exists?
          raise StandardError,
                "File id:#{a.id} of type #{attachment_name} is missing"
        end
        yield if block_given?
        dir = FileUtils.mkdir_p(File.join(dir_name, a.id.to_s)).first
        if defined?(S3_BUCKET)
          s3_asset =
            S3_BUCKET.object(a.public_send(attachment_name).path.remove(%r{^/}))
          file_name = a.public_send(attachment_name).original_filename
          File.open(File.join(dir, file_name), 'wb') do |f|
            s3_asset.get(response_target: f)
          end
        else
          FileUtils.cp(
            a.public_send(attachment_name).path,
            File.join(dir, a.public_send(attachment_name).original_filename)
          )
        end
      end
    end

    def export_to_dir
      raise NotImplementedError, '#export_to_dir method not implemented.'
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
  end
end

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
        next unless a.public_send(attachment_name).attached?
        blob = a.public_send(attachment_name).blob
        dir = FileUtils.mkdir_p(File.join(dir_name, a.id.to_s)).first
        destination_path = File.join(dir, a.file_name)

        blob.open do |file|
          FileUtils.cp(file.path, destination_path)
        end

        yield if block_given?
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
        assets: step.assets.map { |a| assets_data(a) },
        step_tables: step.step_tables,
        tables: step.tables.map { |t| table(t) }
      }
    end

    def assets_data(asset)
      return unless asset.file.attached?

      {
        asset: asset,
        asset_blob: asset.file.blob
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

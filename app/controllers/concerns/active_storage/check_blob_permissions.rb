# frozen_string_literal: true

module ActiveStorage
  module CheckBlobPermissions
    extend ActiveSupport::Concern

    included do
      before_action :check_read_permissions
    end

    private

    def check_read_permissions
      case @blob.attachments.first.record_type
      when 'Asset'
        check_asset_read_permissions
      when 'TinyMceAsset'
        check_tinymce_asset_read_permissions
      when 'Experiment'
        check_experiment_read_permissions
      when 'User'
        # No read restrictions for avatars
        true
      when 'ZipExport', 'TeamZipExport'
        check_zip_export_read_permissions
      else
        render_403
      end
    end

    def check_asset_read_permissions
      asset = @blob.attachments.first.record
      return render_403 unless asset

      if asset.step
        protocol = asset.step.protocol
        render_403 unless can_read_protocol_in_module?(protocol) || can_read_protocol_in_repository?(protocol)
      elsif asset.result
        experiment = asset.result.my_module.experiment
        render_403 unless can_read_experiment?(experiment)
      elsif asset.repository_cell
        repository = asset.repository_cell.repository_column.repository
        render_403 unless can_read_team?(repository.team)
      else
        render_403
      end
    end

    def check_tinymce_asset_read_permissions
      asset = @blob.attachments.first.record
      return render_403 unless asset
      return true if asset.object.nil? && asset.team == current_team

      case asset.object_type
      when 'MyModule'
        render_403 unless can_read_experiment?(asset.object.experiment)
      when 'Protocol'
        render_403 unless can_read_protocol_in_module?(asset.object) ||
                          can_read_protocol_in_repository?(asset.object)
      when 'ResultText'
        render_403 unless can_read_experiment?(asset.object.result.my_module.experiment)
      when 'Step'
        render_403 unless can_read_protocol_in_module?(asset.object.protocol) ||
                          can_read_protocol_in_repository?(asset.object.protocol)
      else
        render_403
      end
    end

    def check_experiment_read_permissions
      render_403 && return unless can_read_experiment?(@blob.attachments.first.record)
    end

    def check_zip_export_read_permissions
      render_403 unless @blob.attachments.first.record.user == current_user
    end
  end
end

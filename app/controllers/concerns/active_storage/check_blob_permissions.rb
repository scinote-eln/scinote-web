# frozen_string_literal: true

module ActiveStorage
  module CheckBlobPermissions
    extend ActiveSupport::Concern

    included do
      before_action :check_read_permissions
    end

    private

    def check_read_permissions
      return render_404 if @blob.attachments.blank?

      render_403 unless @blob.attachments.any? { |attachment| check_attachment_read_permissions(attachment) }
    end

    def check_attachment_read_permissions(attachment)
      current_user.permission_team = attachment.record.team if attachment.record.respond_to?(:team)

      return false if attachment.record.blank?

      case attachment.record_type
      when 'Asset'
        check_asset_read_permissions(attachment.record)
      when 'TinyMceAsset'
        check_tinymce_asset_read_permissions(attachment.record)
      when 'Experiment'
        can_read_experiment?(attachment.record)
      when 'Report'
        can_read_project?(attachment.record.project)
      when 'User'
        # No read restrictions for avatars
        true
      when 'ZipExport', 'TeamZipExport'
        attachment.record.user == current_user
      when 'TempFile'
        attachment.record.session_id == request.session_options[:id].to_s
      else
        false
      end
    end

    def check_asset_read_permissions(asset)
      if asset.step
        protocol = asset.step.protocol
        can_read_protocol_in_module?(protocol) || can_read_protocol_in_repository?(protocol)
      elsif asset.result
        experiment = asset.result.my_module.experiment
        can_read_experiment?(experiment)
      elsif asset.repository_cell
        repository = asset.repository_cell.repository_column.repository
        can_read_repository?(repository)
      else
        false
      end
    end

    def check_tinymce_asset_read_permissions(asset)
      return true if asset.object.nil? && can_read_team?(asset.team)

      case asset.object_type
      when 'MyModule'
        can_read_my_module?(asset.object)
      when 'Protocol'
        can_read_protocol_in_module?(asset.object) || can_read_protocol_in_repository?(asset.object)
      when 'ResultText'
        can_read_my_module?(asset.object.result.my_module)
      when 'StepText'
        can_read_protocol_in_module?(asset.object.step.protocol) ||
          can_read_protocol_in_repository?(asset.object.step.protocol)
      else
        false
      end
    end
  end
end

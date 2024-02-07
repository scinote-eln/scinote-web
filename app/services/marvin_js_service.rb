# frozen_string_literal: true

class MarvinJsService
  class << self
    def url
      ENV['MARVINJS_URL']
    end

    def enabled?
      !ENV['MARVINJS_URL'].nil? || !ENV['MARVINJS_API_KEY'].nil?
    end

    def create_sketch(params, current_user, current_team)
      file = generate_image(params)
      if params[:object_type] == 'TinyMceAsset'
        asset = TinyMceAsset.new(team_id: current_team.id)
        attach_file(asset.image, file, params)
        asset.save!
        return { asset: asset }
      end

      asset = Asset.new(created_by: current_user,
                          last_modified_by: current_user,
                          team_id: current_team.id)
      attach_file(asset.file, file, params)
      asset.save!
      asset.post_process_file
      connect_asset(asset, params, current_user)
    end

    def update_sketch(params, current_user, current_team)
      if params[:object_type] == 'TinyMceAsset'
        asset = current_team.tiny_mce_assets.find(Base62.decode(params[:id]))
        attachment = asset&.image
      else
        asset = current_team.assets.find(params[:id])
        attachment = asset&.file
      end
      return unless attachment

      file = generate_image(params)
      asset.update(last_modified_by: current_user) if asset.is_a?(Asset)
      attach_file(attachment, file, params)
      asset.post_process_file if asset.instance_of?(Asset)
      asset
    end

    private

    def connect_asset(asset, params, current_user)
      object = case params[:object_type]
               when 'Step'
                 Step.find(params[:object_id])
               when 'Result'
                 Result.find(params[:object_id])
               end
      asset.update!(view_mode: object.assets_view_mode)
      object.assets << asset

      { asset: asset, object: object }
    end

    def generate_image(params)
      StringIO.new(Base64.decode64(params[:image].split(',')[1]))
    end

    def attach_file(asset, file, params)
      asset.attach(
        io: file,
        filename: "#{prepare_name(params[:name])}.jpg",
        content_type: 'image/jpeg',
        metadata: {
          name: prepare_name(params[:name]),
          description: params[:description],
          asset_type: 'marvinjs'
        }
      )
    end

    def prepare_name(sketch_name)
      if !sketch_name.blank?
        sketch_name
      else
        I18n.t('marvinjs.new_sketch')
      end
    end
  end
end

# frozen_string_literal: true

class MarvinJsService
  class << self
    def url
      ENV['MARVINJS_URL']
    end

    def enabled?
      !ENV['MARVINJS_URL'].nil? || !ENV['MARVINJS_API_KEY'].nil?
    end

    def create_asset_sketch(object, params, current_user, current_team)
      file = generate_image(params[:image])
      asset = Asset.create!(created_by: current_user, last_modified_by: current_user, team_id: current_team.id)
      asset_attach_file_version(asset, file, params)
      asset.post_process_file
      asset.update!(view_mode: object.assets_view_mode)
      object.assets << asset
      asset
    end

    def create_tinymce_sketch(params, current_team)
      file = generate_image(params[:image])
      tiny_mce_asset = TinyMceAsset.create!(team_id: current_team.id)
      tinymce_attach_file(tiny_mce_asset, file, params)
      tiny_mce_asset
    end

    def update_asset_sketch(asset, params, current_user)
      file = generate_image(params[:image])
      asset_attach_file_version(asset, file, params)
      asset.update!(last_modified_by: current_user)
      asset.post_process_file
      asset
    end

    def update_tinymce_sketch(tiny_mce_asset, params)
      file = generate_image(params[:image])
      tinymce_attach_file(tiny_mce_asset, file, params)
      tiny_mce_asset
    end

    private

    def generate_image(image)
      StringIO.new(Base64.decode64(image.split(',')[1]))
    end

    def tinymce_attach_file(tiny_mce_asset, file, params)
      tiny_mce_asset.image.attach(
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

    def asset_attach_file_version(asset, file, params)
      asset.attach_file_version(
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

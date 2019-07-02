# frozen_string_literal: true

class MarvinJsService
  class << self
    def url
      ENV['MARVINJS_URL']
    end

    def enabled?
      !ENV['MARVINJS_URL'].nil? || !ENV['MARVINJS_API_KEY'].nil?
    end

    def create_sketch(params, current_user)
      file = generate_image(params)
      asset = Asset.new(created_by: current_user, team_id: current_user.current_team.id)
      asset.team_id = current_user.current_team.id
      attach_file(asset, file, params)
      asset.save!
      connect_asset(asset, params)
      asset
    end

    def update_sketch(params, current_user)
      asset = current_user.current_team.assets.find(params[:id])
      return unless asset

      file = generate_image(params)
      asset.file.purge_later
      attach_file(asset, file, params)
      asset
    end

    private

    def connect_asset(asset, params)
      object = params[:object_type].constantize.find(params[:object_id])
      object.assets << asset
    end

    def generate_image(params)
      image_data = Base64.decode64(params[:image].split(',')[1])
      file = Tempfile.new([params[:name], '.jpeg'])
      file.binmode
      file << image_data
      file.rewind
      file
    end

    def attach_file(asset, file, params)
      asset.file.attach(
        io: file,
        filename: "#{params[:name]}.jpeg",
        content_type: 'image/jpeg',
        metadata: {
          name: params[:name],
          description: params[:description],
          asset_type: 'marvinjs'
        }
      )
    end
  end
end

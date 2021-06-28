# frozen_string_literal: true

class BioEddieService
  class << self
    def url
      ApplicationSettings.instance.values['bio_eddie_url']
    end

    def enabled?(current_user)
      url.present? && current_user.settings.fetch('bio_eddie_enabled', false)
    end

    def create_molecule(params, current_user, current_team)
      file = image_io(params)

      asset = Asset.new(created_by: current_user,
                          last_modified_by: current_user,
                          team_id: current_team.id)
      attach_file(asset.file, file, params)
      asset.save!
      asset.post_process_file(current_team)
      connect_asset(asset, params, current_user)
    end

    def update_molecule(params, _current_user, current_team)
      asset = current_team.assets.find(params[:id])
      attachment = asset&.file

      return unless attachment

      file = image_io(params)
      attach_file(attachment, file, params)
      asset
    end

    private

    def connect_asset(asset, params, current_user)
      case params[:object_type]
      when 'Step'
        object = params[:object_type].constantize.find(params[:object_id])
        asset.update!(view_mode: object.assets_view_mode)
        object.assets << asset
      when 'Result'
        my_module = MyModule.find_by(id: params[:object_id])
        return unless my_module

        Result.create(user: current_user,
                      my_module: my_module,
                      name: prepare_name(params[:name]),
                      asset: asset,
                      last_modified_by: current_user)
      end
      asset
    end

    def image_io(params)
      StringIO.new(params[:image])
    end

    def attach_file(attachment, file, params)
      attachment.attach(
        io: file,
        filename: "#{prepare_name(params[:name])}.svg",
        content_type: 'image/svg+xml',
        metadata: {
          name: prepare_name(params[:name]),
          description: params[:description],
          asset_type: 'bio_eddie'
        }
      )
    end

    def prepare_name(sketch_name)
      sketch_name.presence || I18n.t('bio_eddie.new_molecule')
    end
  end
end

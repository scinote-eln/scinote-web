class TinyMceAssetsController < ApplicationController

  def create
    step = Step.find_by_id(params[:step])
    image = Asset.create(file: params[:file],
                         created_by: current_user,
                         team: current_team)
    image.file.reprocess_without_delay!(:original)
    byebug
    render json: {
      image: {
        url: view_context.image_url(image.url(:original))
      }
    }, content_type: 'text/html'
  end

end

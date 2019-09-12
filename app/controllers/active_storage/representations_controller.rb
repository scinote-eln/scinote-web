# frozen_string_literal: true

module ActiveStorage
  class RepresentationsController < BaseController
    include ActiveStorage::SetBlob
    include ActiveStorage::CheckBlobPermissions

    def show
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to @blob.representation(params[:variation_key]).processed.service_url(disposition: params[:disposition])
    end
  end
end

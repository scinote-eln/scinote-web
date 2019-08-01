# frozen_string_literal: true

module ActiveStorage
  class BlobsController < BaseController
    include ActiveStorage::SetBlob
    include ActiveStorage::CheckBlobPermissions

    def show
      expires_in ActiveStorage::Blob.service.url_expires_in
      redirect_to @blob.service_url(disposition: params[:disposition])
    end
  end
end

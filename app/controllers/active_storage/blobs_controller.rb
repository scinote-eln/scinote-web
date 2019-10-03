# frozen_string_literal: true

module ActiveStorage
  class BlobsController < CustomBaseController
    include ActiveStorage::SetBlob
    include ActiveStorage::CheckBlobPermissions

    def show
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to @blob.service_url(disposition: params[:disposition])
    end
  end
end

# frozen_string_literal: true

module ActiveStorage
  module Blobs
    class RedirectController < CustomBaseController
      include ActiveStorage::SetBlob
      include ActiveStorage::CheckBlobPermissions

      def show
        expires_in ActiveStorage.service_urls_expire_in
        redirect_to @blob.url(disposition: params[:disposition]), allow_other_host: true
      end
    end
  end
end

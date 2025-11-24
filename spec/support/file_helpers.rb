module FileHelpers
  def create_signed_blob_id(filename:, content_type:, content:)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    )
    blob.signed_id
  end
end

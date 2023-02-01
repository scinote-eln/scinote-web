# frozen_string_literal: true

module ActiveStorageFileUtil
  # Method expects instance of ActiveStorage::Blob as argument
  def previewable_document?(blob)
    previewable = Constants::PREVIEWABLE_FILE_TYPES.include?(blob.content_type)

    file_extension = blob.filename.extension
    content_type = blob.content_type

    extensions = %w(.xlsx .docx .pptx .xls .doc .ppt)
    # Mimetype sometimes recognizes Office files as zip files
    # In this case we also check the extension of the given file
    # Otherwise the conversion should fail if the file is being something else
    previewable ||= (content_type == 'application/zip' && extensions.include?(file_extension))

    # Mimetype also sometimes recognizes '.xls' and '.ppt' files as
    # application/x-ole-storage (https://github.com/minad/mimemagic/issues/50)
    previewable ||= (content_type == 'application/x-ole-storage' && %w(.xls .ppt).include?(file_extension))

    previewable
  end

  module_function :previewable_document?
end

class ZipExport < ActiveRecord::Base
  belongs_to :user
  has_attached_file :zip_file
  validates_attachment :zip_file,
                       content_type: { content_type: 'application/zip' }
end

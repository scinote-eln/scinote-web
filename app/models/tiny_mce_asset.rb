class TinyMceAsset < ActiveRecord::Base
  attr_accessor :reference
  before_create :set_reference

  belongs_to :step
  belongs_to :result_text
  has_attached_file :image,
                    styles: { medium: [Constants::MEDIUM_PIC_FORMAT, :jpg] },
                    convert_options: { medium: '-quality 70 -strip' }

  validates_attachment_content_type :image,
                                    content_type: %r{^image/#{ Regexp.union(
                                      Constants::WHITELISTED_IMAGE_TYPES
                                    ) }}
  # When using S3 file upload, we can limit file accessibility with url signing
  def presigned_url(style = :medium,
                    download: false,
                    timeout: Constants::URL_SHORT_EXPIRE_TIME)
    if stored_on_s3?
      if download
        download_arg = 'attachment; filename=' + URI.escape(image_file_name)
      else
        download_arg = nil
      end

      signer = Aws::S3::Presigner.new(client: S3_BUCKET.client)
      signer.presigned_url(:get_object,
                           bucket: S3_BUCKET.name,
                           key: image.path(style)[1..-1],
                           expires_in: timeout,
                           response_content_disposition: download_arg)
    end
  end

  def stored_on_s3?
    image.options[:storage].to_sym == :s3
  end

  def url(style = :medium, timeout: Constants::URL_SHORT_EXPIRE_TIME)
    if image.is_stored_on_s3?
      presigned_url(style, timeout: timeout)
    else
      image.url(style)
    end
  end

  def set_reference
    obj_type = "#{@reference.class.to_s.underscore}=".to_sym
    self.public_send(obj_type, @reference) if @reference
  end
end

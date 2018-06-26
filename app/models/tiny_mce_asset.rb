class TinyMceAsset < ApplicationRecord
  attr_accessor :reference
  before_create :set_reference, optional: true
  after_create :update_estimated_size
  after_destroy :release_team_space

  belongs_to :team, inverse_of: :tiny_mce_assets, optional: true
  belongs_to :step, inverse_of: :tiny_mce_assets, optional: true
  belongs_to :result_text, inverse_of: :tiny_mce_assets, optional: true
  has_attached_file :image,
                    styles: { large: [Constants::LARGE_PIC_FORMAT, :jpg] },
                    convert_options: { large: '-quality 100 -strip' }

  validates_attachment_content_type :image,
                                    content_type: %r{^image/#{ Regexp.union(
                                      Constants::WHITELISTED_IMAGE_TYPES
                                    ) }}
  validates_attachment :image,
                       presence: true,
                       size: {
                         less_than: Rails.configuration.x.file_max_size_mb.megabytes
                       }
  validates :estimated_size, presence: true

  # When using S3 file upload, we can limit file accessibility with url signing
  def presigned_url(style = :large,
                    download: false,
                    timeout: Constants::URL_LONG_EXPIRE_TIME)
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

  def url(style = :large, timeout: Constants::URL_LONG_EXPIRE_TIME)
    if image.is_stored_on_s3?
      presigned_url(style, timeout: timeout)
    else
      image.url(style)
    end
  end

  def open
    if image.is_stored_on_s3?
      Kernel.open(presigned_url, 'rb')
    else
      File.open(image.path, 'rb')
    end
  end

  private

  def update_estimated_size
    return if image_file_size.blank?
    es = image_file_size * Constants::ASSET_ESTIMATED_SIZE_FACTOR
    update(estimated_size: es)
    Rails.logger.info "Asset #{id}: Estimated size successfully calculated"
    # update team space taken
    self.team.take_space(es)
    self.team.save
  end

  def release_team_space
    self.team.release_space(estimated_size)
    self.team.save
  end

  def set_reference
    obj_type = "#{@reference.class.to_s.underscore}=".to_sym
    public_send(obj_type, @reference) if @reference
  end
end

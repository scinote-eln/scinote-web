AssetTextExtractionJob = Struct.new(:asset_id, :in_template) do
  def perform
    asset = Asset.find_by(id: asset_id)
    return unless asset.present? && asset.file.attached?

    asset.extract_asset_text(in_template)
  end

  def queue_name
    'assets'
  end

  def max_attempts
    1
  end

  def max_run_time
    5.minutes
  end
end

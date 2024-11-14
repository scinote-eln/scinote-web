module StorageLocationsHelper
  def storage_locations_placeholder
    return if StorageLocation.storage_locations_enabled?

    "<div class=\"p-4 rounded bg-sn-super-light-blue\">
      #{I18n.t('storage_locations.storage_locations_disabled')}
    </div>"
  end
end

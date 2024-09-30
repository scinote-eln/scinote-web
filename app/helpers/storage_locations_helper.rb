module StorageLocationsHelper
  def storage_locations_placeholder
    "<div class=\"p-4 rounded bg-sn-super-light-blue\">
      #{I18n.t('storage_locations.storage_locations_disabled')}
    </div>"
  end
end

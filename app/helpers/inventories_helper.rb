# frozen_string_literal: true

module InventoriesHelper
  def inventory_shared_status_icon(inventory, team)
    if inventory.shared_with?(team)
      if inventory.shared_with_write?(team)
        draw_custom_icon('shared-edit')
      else
        draw_custom_icon('shared-read')
      end
    else
      # The icon should be hiden if repo is not shared (we're updating it dinamically)
      css_classes = ["repository-share-status"]
      css_classes.push("hidden") unless inventory.i_shared?(current_team)

      content_tag :span, class: css_classes.join(" ") do
        draw_custom_icon('i-shared')
      end
    end
  end
end

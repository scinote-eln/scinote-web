# frozen_string_literal: true

module InventoriesHelper
  def inventory_shared_status_icon(inventory, team)
    if inventory.shared_with?(team)
      if can_manage_repository_rows?(inventory)
        draw_custom_icon('shared-edit', inventory.team)
      else
        draw_custom_icon('shared-read', inventory.team)
      end
    else
      # The icon should be hiden if repo is not shared (we're updating it dinamically)
      css_classes = ["repository-share-status"]
      css_classes.push("hidden") unless inventory.i_shared?(team)
      css_title = t('repositories.icon_title.i_shared')

      content_tag :span, title: css_title, class: css_classes.join(" ") do
        draw_custom_icon('i-shared')
      end
    end
  end
end

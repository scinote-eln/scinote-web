# frozen_string_literal: true

module InventoriesHelper
  def inventory_shared_status_icon(inventory, team)
    if inventory.shared_with?(team)
      if inventory.shared_with_write?(team)
        draw_custom_icon('shared-edit')
      else
        draw_custom_icon('shared-read')
      end
    elsif inventory.shared_with_anybody?
      draw_custom_icon('i-shared')
    end
  end
end

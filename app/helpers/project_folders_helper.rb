# frozen_string_literal: true

module ProjectFoldersHelper
  def items_label(items)
    if items == 'projects'
      I18n.t('projects.index.modal_move_folder.items.projects')
    elsif items == 'folders'
      I18n.t('projects.index.modal_move_folder.items.folders')
    else
      I18n.t('projects.index.modal_move_folder.items.projects_and_folders')
    end
  end
end

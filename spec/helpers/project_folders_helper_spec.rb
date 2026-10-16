# frozen_string_literal: true

require 'rails_helper'

describe ProjectFoldersHelper, type: :helper do
  describe '#items_label' do
    it 'returns the projects label' do
      expect(helper.items_label('projects')).to eq I18n.t('projects.index.modal_move_folder.items.projects')
    end

    it 'returns the folders label' do
      expect(helper.items_label('folders')).to eq I18n.t('projects.index.modal_move_folder.items.folders')
    end

    it 'returns the combined label for anything else' do
      expect(helper.items_label('other'))
        .to eq I18n.t('projects.index.modal_move_folder.items.projects_and_folders')
    end
  end

  describe '#tree_ordered_parent_folders' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let!(:root) { create :project_folder, team: team }
    let!(:middle) { create :project_folder, team: team, parent_folder: root }
    let!(:leaf) { create :project_folder, team: team, parent_folder: middle }

    it 'returns nil without a folder' do
      expect(helper.tree_ordered_parent_folders(nil)).to be_nil
    end

    it 'returns the folder path from the root down to the current folder' do
      expect(helper.tree_ordered_parent_folders(leaf)).to eq [root, middle, leaf]
    end

    it 'returns only the folder itself for a root folder' do
      expect(helper.tree_ordered_parent_folders(root)).to eq [root]
    end
  end
end

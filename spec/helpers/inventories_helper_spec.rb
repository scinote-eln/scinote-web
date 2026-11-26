# frozen_string_literal: true

require 'rails_helper'

describe InventoriesHelper, type: :helper do
  let(:user) { create :user }
  let(:owner_team) { create :team, created_by: user }
  let(:other_team) { create :team, created_by: user }
  let(:inventory) { create :repository, team: owner_team, created_by: user }

  describe '#inventory_shared_status_icon' do
    it 'renders the shared-edit icon when the user can manage rows' do
      create :team_shared_object, :write, team: other_team, shared_object: inventory
      without_partial_double_verification { allow(helper).to receive(:can_manage_repository_rows?).with(inventory).and_return(true) }

      html = helper.inventory_shared_status_icon(inventory, other_team)

      expect(html).to include(I18n.t('repositories.icon_title.shared_edit', team_name: owner_team.name))
    end

    it 'renders the shared-read icon when the user cannot manage rows' do
      create :team_shared_object, :read, team: other_team, shared_object: inventory
      without_partial_double_verification { allow(helper).to receive(:can_manage_repository_rows?).with(inventory).and_return(false) }

      html = helper.inventory_shared_status_icon(inventory, other_team)

      expect(html).to include(I18n.t('repositories.icon_title.shared_read', team_name: owner_team.name))
    end

    it 'renders a hidden status marker for an inventory that is not shared' do
      html = helper.inventory_shared_status_icon(inventory, owner_team)

      expect(html).to include('class="repository-share-status hidden"')
      expect(html).to include("title=\"#{I18n.t('repositories.icon_title.i_shared')}\"")
    end

    it 'renders a visible status marker for the sharing team' do
      create :team_shared_object, :read, team: other_team, shared_object: inventory

      html = helper.inventory_shared_status_icon(inventory, owner_team)

      expect(html).to include('class="repository-share-status"')
      expect(html).not_to include('hidden')
    end
  end
end

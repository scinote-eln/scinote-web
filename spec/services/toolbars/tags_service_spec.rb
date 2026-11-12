# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toolbars::TagsService do
  let(:user) { create :user }
  let(:viewer) { create :user }
  let(:team) { create :team, created_by: user }
  before { [user, viewer].each { |u| u.update!(current_team_id: team.id) } }

  let!(:tag) { create :tag, team: team, created_by: user }
  let!(:other_tag) { create :tag, created_by: user }

  def actions_for(ids, service_user: user)
    described_class.new(service_user, team, tag_ids: ids).actions
  end

  it 'returns no actions without matching tags' do
    expect(actions_for([])).to eq []
    expect(actions_for([other_tag.id])).to eq []
  end

  it 'returns merge and delete actions for an admin' do
    actions = actions_for([tag.id])
    expect(actions.pluck(:name)).to eq %w(merge delete)
    expect(actions.pluck(:type).uniq).to eq [:emit]
  end

  it 'builds the delete path with the selected tag ids' do
    t2 = create :tag, team: team, created_by: user
    delete = actions_for([tag.id, t2.id]).find { |a| a[:name] == 'delete' }
    expect(delete[:path]).to eq Rails.application.routes.url_helpers
                                     .destroy_tags_team_tags_path(team, tag_ids: [tag.id, t2.id])
  end

  context 'with a user without tag permissions' do
    before do
      role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
      create_user_assignment(team, role, viewer)
    end

    it 'returns no actions' do
      expect(actions_for([tag.id], service_user: viewer)).to eq []
    end
  end

  context 'when only delete is permitted' do
    it 'omits the merge action' do
      service = described_class.new(user, team, tag_ids: [tag.id])
      without_partial_double_verification do
        allow(service).to receive(:can_create_tags?).and_return(false)
      end
      expect(service.actions.pluck(:name)).to eq ['delete']
    end
  end
end

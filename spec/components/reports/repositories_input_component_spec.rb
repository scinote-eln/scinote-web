# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::RepositoriesInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report) { create :report, user: user, project: project, team: team }
  let!(:zeta) { create :repository, name: 'zeta items', team: team, created_by: user }
  let!(:alpha) { create :repository, name: 'Alpha items', team: team, created_by: user }

  before { user.update!(current_team_id: team.id) }

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'repos', label: 'Inventories', user: user, **opts))
  end

  context 'when editing' do
    it 'renders a multiple select of readable repositories sorted case-insensitively by name' do
      page = render_component
      select = page.at_css('select[name="repos[]"]')
      expect(select['multiple']).to be_present
      expect(select['data-type']).to eq 'RepositoriesInputComponent'
      expect(select.css('option').map(&:text)).to eq ['Alpha items', 'zeta items']
    end

    it 'excludes repositories of other teams' do
      other = create :repository, name: 'Foreign', team: create(:team)
      expect(render_component.css('option').map { |o| o['value'] }).not_to include(other.id.to_s)
    end

    it 'appends snapshots of deleted repositories once per parent' do
      snapshot_source = create :repository, name: 'Gone source', team: team, created_by: user
      snapshot = create :repository_snapshot, original_repository: snapshot_source, team: team,
                                              created_by: user, name: 'Gone snapshot'
      snapshot_source.destroy!

      options = render_component.css('option')
      expect(options.map(&:text)).to eq ['Alpha items', 'zeta items', 'Gone snapshot']
      expect(options.last['value']).to eq snapshot.id.to_s
    end

    it 'preselects the stored repositories' do
      report.report_template_values.create!(view_component: 'RepositoriesInputComponent', name: 'repos', value: [alpha.id])
      expect(render_component.css('option[selected]').map { |o| o['value'] }).to eq [alpha.id.to_s]
    end
  end

  context 'when not editing' do
    # bug: the template reads @project_members, which this component never sets, so the read-only view raises
    pending 'bug: read-only rendering raises NoMethodError on nil @project_members' do
      report.report_template_values.create!(view_component: 'RepositoriesInputComponent', name: 'repos', value: [alpha.id])
      expect(render_component(editing: false).text.strip).to eq 'Alpha items'
    end
  end
end

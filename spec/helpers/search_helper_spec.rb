# frozen_string_literal: true

require 'rails_helper'

describe SearchHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:other_team) { create :team, created_by: user }

  describe '#experiments_results' do
    # bug: SearchHelper#experiments_results calls Tag#my_modules, which does not exist
    # (Tag only has `taggings`), so the helper raises NoMethodError for every tag.
    it 'returns the distinct experiments of the tag tasks' do
      pending 'bug: Tag#my_modules is undefined, experiments_results raises NoMethodError'
      project = create :project, team: team, created_by: user
      experiment_a = create :experiment, project: project, created_by: user
      experiment_b = create :experiment, project: project, created_by: user
      tag = create :tag, team: team
      [experiment_a, experiment_a, experiment_b].each do |experiment|
        mod = create :my_module, experiment: experiment, created_by: user
        create :tagging, tag: tag, taggable: mod, created_by: user
      end

      expect(helper.experiments_results(tag.reload)).to contain_exactly(experiment_a, experiment_b)
    end
  end

  context 'with the current team' do
    before { without_partial_double_verification { allow(helper).to receive(:current_team).and_return(team) } }

    describe '#route_to_other_team' do
      it 'links without confirmation for the current team' do
        html = helper.route_to_other_team('/x', team, 'Go', class: 'link')

        expect(html).to eq '<a class="link" data-turbolinks="false" href="/x">Go</a>'
      end

      it 'asks for confirmation when the result belongs to another team' do
        html = helper.route_to_other_team('/x', other_team, 'Go')

        expect(html).to include('data-turbolinks="false"')
        expect(html).to include("data-confirm=\"#{ERB::Util.html_escape(I18n.t('users.settings.changed_team_in_search', team: other_team.name))}\"")
      end
    end

    describe '#route_to_other_team_btn' do
      it 'renders a plain button link for the current team' do
        expect(helper.route_to_other_team_btn('/x', team, 'Go')).to eq '<a class="btn btn-primary" href="/x">Go</a>'
      end

      it 'asks for confirmation when the result belongs to another team' do
        html = helper.route_to_other_team_btn('/x', other_team, 'Go')

        expect(html).to include('class="btn btn-primary"')
        expect(html).to include("data-confirm=\"#{ERB::Util.html_escape(I18n.t('users.settings.changed_team_in_search', team: other_team.name))}\"")
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe ProjectsHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }

  describe '#projects_view_mode' do
    context 'when a project is given' do
      it 'returns archived for an archived project' do
        project = create :project, :archived, team: team, created_by: user

        expect(helper.projects_view_mode(project: project)).to eq 'archived'
      end

      it 'returns active for a non archived project even when the url asks for archived' do
        project = create :project, team: team, created_by: user
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'archived'))

        expect(helper.projects_view_mode(project: project)).to eq 'active'
      end
    end

    context 'when no project is given' do
      it 'returns archived when the current folder is archived' do
        without_partial_double_verification do
          allow(helper).to receive(:current_folder).and_return(double('ProjectFolder', archived?: true))
        end

        expect(helper.projects_view_mode).to eq 'archived'
      end

      it 'follows the view_mode url parameter when there is no folder' do
        without_partial_double_verification { allow(helper).to receive(:current_folder).and_return(nil) }
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'archived'))

        expect(helper.projects_view_mode).to eq 'archived'
      end

      it 'defaults to active without folder or view_mode parameter' do
        without_partial_double_verification { allow(helper).to receive(:current_folder).and_return(nil) }
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))

        expect(helper.projects_view_mode).to eq 'active'
      end
    end
  end

  describe '#projects_view_mode_archived?' do
    it 'is true only for the archived view mode' do
      without_partial_double_verification { allow(helper).to receive(:current_folder).and_return(nil) }

      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'archived'))
      expect(helper.projects_view_mode_archived?).to be true

      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'active'))
      expect(helper.projects_view_mode_archived?).to be false
    end
  end

  describe '#user_name_with_role' do
    it 'escapes the user name and role name' do
      assignment = double('UserAssignment',
                          user: double('User', name: 'Ann <script>'),
                          user_role: double('UserRole', name: 'Owner & Co'))

      expect(helper.user_name_with_role(assignment)).to eq 'Ann &lt;script&gt; - Owner &amp; Co'
    end
  end

  describe '#user_names_with_roles' do
    it 'joins sanitized name and role pairs with a line break entity' do
      assignments = [
        double('UserAssignment', user: double('User', name: 'Ann'), user_role: double('UserRole', name: 'Owner')),
        double('UserAssignment', user: double('User', name: 'Bob'), user_role: double('UserRole', name: 'Viewer'))
      ]

      result = helper.user_names_with_roles(assignments)

      expect(result).to include 'Ann - Owner'
      expect(result).to include "Ann - Owner\rBob - Viewer"
    end

    it 'removes markup from the names through the sanitizer' do
      assignments = [
        double('UserAssignment', user: double('User', name: '<img src=x onerror=alert(1)>Eve'),
                                 user_role: double('UserRole', name: 'Owner'))
      ]

      result = helper.user_names_with_roles(assignments)

      expect(result).not_to include '<img'
      expect(result).to eq '&lt;img src=x onerror=alert(1)&gt;Eve - Owner'
    end
  end

  describe '#construct_module_connections' do
    it 'returns the ids of the modules this module outputs to, comma separated' do
      outputs = [double('Connection', to: double('MyModule', id: 3)), double('Connection', to: double('MyModule', id: 7))]
      my_module = double('MyModule', outputs: outputs)

      expect(helper.construct_module_connections(my_module)).to eq '3, 7'
    end

    it 'returns an empty string when there are no outputs' do
      expect(helper.construct_module_connections(double('MyModule', outputs: []))).to eq ''
    end
  end

  describe '#folders_tree' do
    let!(:root_folder) { create :project_folder, team: team, name: 'B root' }
    let!(:child_folder) { create :project_folder, team: team, name: 'A child', parent_folder: root_folder }
    let!(:other_folder) { create :project_folder, team: team, name: 'C other' }

    before do
      without_partial_double_verification { allow(helper).to receive(:current_folder).and_return(nil) }
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))
    end

    it 'builds the active folder hierarchy ordered by name' do
      tree = helper.folders_tree(team, user)

      expect(tree.map { |node| node[:folder].name }).to eq ['B root', 'C other']
      expect(tree.first[:children].map { |node| node[:folder].name }).to eq ['A child']
      expect(tree.first[:children].first[:children]).to eq []
    end

    it 'nests a project and a sub folder under the folder they are placed in' do
      project = create :project, team: team, created_by: user, name: 'P in root', project_folder: root_folder,
                                 visibility: 'visible'

      # folders_tree only feeds folders; projects reach the builder when a caller passes them in
      tree = helper.send(:folders_recursive_builder, root_folder, [project, child_folder])

      expect(tree).to contain_exactly(hash_including(project: project), hash_including(folder: child_folder))
    end

    it 'only includes archived folders in the archived view' do
      archived = create :project_folder, team: team, name: 'Z archived', archived: true
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'archived'))

      tree = helper.folders_tree(team, user)

      expect(tree.map { |node| node[:folder].id }).to eq [archived.id]
    end
  end
end

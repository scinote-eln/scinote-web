# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::TagToHtml do
  let!(:user) { create :user }
  let!(:team) { create :team, :change_user_team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let!(:project) { create :project, name: 'my project', team: team }
  let!(:user_assignment) do
    create :user_assignment,
           assignable: project,
           user: user,
           user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner')),
           assigned_by: user
  end
  let(:text) do
    "My annotation of [#my project~prj~#{project.id.base62_encode}]"
  end
  let(:subject) { described_class.new(user, team, text) }
  describe 'Parsed text' do
    it 'returns a existing string with smart annotation' do
      expect(subject.html).to eq(
        "My annotation of <a class='sa-link' href='/projects/#{project.id}/experiments'>" \
        "<span class='sa-type'>Prj</span>my project</a>"
      )
    end
  end

  describe 'Parsed text with file annotation' do
    let!(:experiment) { create :experiment, project: project, created_by: user }
    let!(:task) { create :my_module, experiment: experiment, created_by: user }
    let!(:protocol) { create :protocol, team: team, my_module: task }
    let!(:step) { create :step, protocol: protocol }
    let!(:step_asset) { create :step_asset, step: step }
    let(:asset) { Asset.find(step_asset.asset_id) }
    let(:text) { "File: [##{asset.file_name}~file~#{asset.id.base62_encode}]" }
    let(:subject) { described_class.new(user, team, text) }

    it 'returns a html snippet for the file' do
      expect(subject.html).to eq(
        "File: <a class='sa-link file-preview-link file-name' href='" \
        "#{Rails.application.routes.url_helpers.rails_blob_path(asset.file, disposition: 'attachment')}' " \
        "data-no-turbolink='true' data-id='#{asset.id}' data-preview-url='/files/#{asset.id}/preview?preview=true'>" \
        "<span class='sa-type'>Fl</span>#{asset.file_name}</a>"
      )
    end
  end

  describe '#extract_values/1' do
    it 'returns a parsed hash of smart annotation' do
      values = subject.send(:extract_values, '[#my project~prj~1]')
      expect(values[:name]).to eq 'my project'
      expect(values[:object_id]).to eq 1
      expect(values[:object_type]).to eq 'prj'
    end
  end

  describe '#fetch_object/2' do
    it 'rises an error if type is not valid' do
      expect do
        subject.send(:fetch_object, 'banana', project.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns the required object' do
      expect(subject.send(:fetch_object, 'prj', project.id)).to eq project
    end
  end
end

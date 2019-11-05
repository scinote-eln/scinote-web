# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::TagToHtml do
  let!(:user) { create :user }
  let!(:team) { create :team }
  let!(:user_team) { create :user_team, user: user, team: team, role: 2 }
  let!(:project) { create :project, name: 'my project', team: team }
  let!(:user_project) do
    create :user_project, project: project, user: user, role: 0
  end
  let(:text) do
    "My annotation of [#my project~prj~#{project.id.base62_encode}]"
  end
  let(:subject) { described_class.new(user, team, text) }
  describe 'Parsed text' do
    it 'returns a existing string with smart annotation' do
      expect(subject.html).to eq(
        "My annotation of <span class='sa-type'>Prj</span> "\
        "<a href='/projects/#{project.id}'>my project</a>"
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

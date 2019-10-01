# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::HtmlPreview do
  let(:subject) { described_class }
  let(:user) { create :user }
  let(:project) { create :project, name: 'my project' }
  let(:experiment) do
    create :experiment, name: 'my experiment',
                        project: project,
                        created_by: user,
                        last_modified_by: user
  end
  let(:task) { create :my_module, name: 'task', experiment: experiment }

  describe 'Project annotations with type prj' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'prj', project)
      expect(snippet).to eq(
        "<span class='sa-type'>Prj</span> " \
        "<a href='/projects/#{project.id}'>my project</a>"
      )
    end
  end

  context 'Experiment annotations with type exp' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'exp', experiment)
      expect(snippet).to eq(
        "<span class='sa-type'>Exp</span> " \
        "<a href='/experiments/#{experiment.id}/canvas'>my experiment</a>"
      )
    end
  end

  context 'MyModule annotations with type tsk' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'tsk', task)
      expect(snippet).to eq(
        "<span class='sa-type'>Tsk</span> " \
        "<a href='/modules/#{task.id}/protocols'>task</a>"
      )
    end
  end

  context 'Repository item annotations with type rep_item' do
    it 'returns a html snippet' do
      snippet = subject.html('my item', 'rep_item', nil)
      expect(snippet).to eq(
        '<span class=\'sa-type\'>Inv</span> my item (deleted)'
      )
    end
  end

  context '#trim_repository_name/1' do
    describe 'repository name with one word' do
      it 'is returns a 3 letter capitalize string' do
        trimmed_repository_name = subject.__send__(
          :trim_repository_name, 'banana'
        )
        expect(trimmed_repository_name).to eq('Ban')
      end
    end

    describe 'repository name with two words' do
      it 'returns the first two letters of first word ' \
         'and the first letter of second word' do
        trimmed_repository_name = subject.__send__(
          :trim_repository_name, 'two words'
        )
        expect(trimmed_repository_name).to eq('Tww')
      end

      it 'does not return 3 letters of the first word' do
        trimmed_repository_name = subject.__send__(
          :trim_repository_name, 'two words'
        )
        expect(trimmed_repository_name).not_to eq('Two')
      end
    end

    describe 'repository name with three words' do
      it 'returns the first letter of first 3 words capitalized' do
        trimmed_repository_name = subject.__send__(
          :trim_repository_name, 'two words of wisdom'
        )
        expect(trimmed_repository_name).to eq('Two')
      end
    end
  end
end

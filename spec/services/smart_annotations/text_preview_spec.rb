# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::TextPreview do
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

  describe 'Project annotations' do
    it 'returns a text snippet' do
      snippet = subject.text(nil, 'prj', project)
      expect(snippet).to eq(project.name)
    end
  end

  context 'Experiment annotations' do
    it 'returns a text snippet' do
      snippet = subject.text(nil, 'exp', experiment)
      expect(snippet).to eq(experiment.name)
    end
  end

  context 'MyModule annotations' do
    it 'returns a text snippet' do
      snippet = subject.text(nil, 'tsk', task)
      expect(snippet).to eq(task.name)
    end
  end

  context 'Repository item annotations with type rep_item' do
    it 'returns a html snippet' do
      snippet = subject.text('my item', 'rep_item', nil)
      expect(snippet).to eq('my item (deleted)')
    end
  end
end

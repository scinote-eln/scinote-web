# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::TextPreview do
  let(:subject) { described_class }
  let(:user) { create :user }
  let(:project) { create :project, name: 'my project', created_by: user }
  let(:experiment) do
    create :experiment, name: 'my experiment',
                        project: project,
                        created_by: user,
                        last_modified_by: user
  end
  let(:task) { create :my_module, name: 'task', experiment: experiment, created_by: experiment.created_by }

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

  context 'Asset annotations with type file' do
    let(:protocol) { create :protocol, my_module: task }
    let(:step) { create :step, protocol: protocol }
    let(:step_asset) { create :step_asset, step: step }
    let(:asset) { Asset.find(step_asset.asset_id) }

    it 'returns a text snippet with the file name and code when there is no title' do
      snippet = subject.text(nil, 'file', asset)
      expect(snippet).to eq("#{asset.file_name}_#{asset.code}")
    end

    it 'returns a text snippet with the file title when one is set' do
      asset.update!(file_title: 'My file title')
      snippet = subject.text(nil, 'file', asset)
      expect(snippet).to eq("My file title_#{asset.code}")
    end

    it 'appends the page number when a page is mentioned' do
      snippet = subject.text(nil, 'file', asset, page: '12')
      expect(snippet).to eq("#{asset.file_name}_#{asset.code}_p12")
    end

    it 'returns an archived snippet when the file is archived' do
      asset.archive!(user)
      snippet = subject.text(nil, 'file', asset)
      expect(snippet).to eq("#{asset.file_name}_#{asset.code} (archived)")
    end

    it 'falls back to the tag-captured name when the file was deleted' do
      snippet = subject.text('old_file.pdf', 'file', nil)
      expect(snippet).to eq('old_file.pdf (deleted)')
    end
  end

  context 'Repository item annotations with type rep_item' do
    it 'returns a html snippet' do
      snippet = subject.text('my item', 'rep_item', nil)
      expect(snippet).to eq('my item (deleted)')
    end
  end
end

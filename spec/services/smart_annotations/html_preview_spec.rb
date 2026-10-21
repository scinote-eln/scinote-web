# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::HtmlPreview do
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

  describe 'Project annotations with type prj' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'prj', project)
      expect(snippet).to eq(
        "<a class='sa-link' href='/projects/#{project.id}/experiments'>" \
        "<span class='sa-type'>Prj</span>my project</a>"
      )
    end
  end

  context 'Experiment annotations with type exp' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'exp', experiment)
      expect(snippet).to eq(
        "<a class='sa-link' href='/experiments/#{experiment.id}/my_modules'>" \
        "<span class='sa-type'>Exp</span>my experiment</a>"
      )
    end
  end

  context 'MyModule annotations with type tsk' do
    it 'returns a html snippet' do
      snippet = subject.html(nil, 'tsk', task)
      expect(snippet).to eq(
        "<a class='sa-link' href='/modules/#{task.id}/protocols'>" \
        "<span class='sa-type'>Tsk</span>task</a>"
      )
    end
  end

  context 'Asset annotations with type file' do
    let(:protocol) { create :protocol, my_module: task }
    let(:step) { create :step, protocol: protocol }
    let(:step_asset) { create :step_asset, step: step }
    let(:asset) { Asset.find(step_asset.asset_id) }

    def file_link(asset, label)
      "<a class='sa-link file-preview-link file-name' href='" \
        "#{Rails.application.routes.url_helpers.rails_blob_path(asset.file, disposition: 'attachment')}' " \
        "data-no-turbolink='true' data-id='#{asset.id}' data-preview-url='/files/#{asset.id}/preview?preview=true'>" \
        "<span class='sa-type'>Fl</span>#{label}</a>"
    end

    it 'returns a html snippet with the file name and code when there is no title' do
      snippet = subject.html(nil, 'file', asset)
      expect(snippet).to eq(file_link(asset, "#{asset.file_name}_#{asset.code}"))
    end

    it 'returns a html snippet with the file title when one is set' do
      asset.update!(file_title: 'My file title')
      snippet = subject.html(nil, 'file', asset)
      expect(snippet).to eq(file_link(asset, "My file title_#{asset.code}"))
    end

    it 'appends the page number when a page is mentioned' do
      snippet = subject.html(nil, 'file', asset, page: '12')
      expect(snippet).to eq(file_link(asset, "#{asset.file_name}_#{asset.code}_p12"))
    end

    it 'returns an archived snippet when the file is archived' do
      asset.archive!(user)
      snippet = subject.html(nil, 'file', asset)
      expect(snippet).to eq("<span class='sa-type'>Fl</span>#{asset.file_name}_#{asset.code} (archived)")
    end

    it 'falls back to the tag-captured name when the file was deleted' do
      snippet = subject.html('old_file.pdf', 'file', nil)
      expect(snippet).to eq("<span class='sa-type'>Fl</span>old_file.pdf (deleted)")
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

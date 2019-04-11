# frozen_string_literal: true

require 'rails_helper'

describe TinyMceAsset, type: :model do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @teams.first)
    @valid_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @valid_project)
    @valid_task = create(:my_module, created_by: @user,
      last_modified_by: @user, experiment: @valid_experiment)
  end

  it 'should be of class TinyMceAsset' do
    expect(subject.class).to eq TinyMceAsset
  end

  describe 'Database table' do
    it { should have_db_column :image_file_name }
    it { should have_db_column :image_content_type }
    it { should have_db_column :image_file_size }
    it { should have_db_column :image_updated_at }
    it { should have_db_column :estimated_size }
    it { should have_db_column :object_id }
    it { should have_db_column :object_type }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to :object }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :estimated_size }
  end

  describe 'Methods' do
    let(:result_text) do
      create :result_text,
             text: '<img data-mce-token=1  src="fake-path"/>',
             result: create(
               :result, user: @user, last_modified_by: @user, my_module: @valid_task
             )
    end
    let(:image) { create :tiny_mce_asset, id: 1 }

    describe '#update_images' do
      it 'save new image' do
        new_image = image
        new_result_text = result_text
        TinyMceAsset.update_images(new_result_text, [Base62.encode(new_image.id)].to_s)
        updated_image = TinyMceAsset.find(new_image.id)
        expect(updated_image.object_type).to eq 'ResultText'
        expect(ResultText.find(new_result_text.id).text).not_to include 'fake-path'
      end
    end

    describe '#generate_url' do
      it 'create new url' do
        image
        expect(TinyMceAsset.generate_url(result_text.text)).to include 'sample_file.jpg'
      end
    end

    describe '#reload_images' do
      it 'change image token in description' do
        new_result_text = result_text
        TinyMceAsset.update_images(new_result_text, [Base62.encode(image.id)].to_s)
        create :tiny_mce_asset, id: 2, object: new_result_text
        TinyMceAsset.reload_images([[1, 2]])
        expect(ResultText.find(new_result_text.id).text).to include 'data-mce-token="2"'
      end
    end
  end
end

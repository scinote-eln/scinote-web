# frozen_string_literal: true

require 'rails_helper'

describe TinyMceAsset, type: :model do
  it 'should be of class TinyMceAsset' do
    expect(subject.class).to eq TinyMceAsset
  end

  describe 'Database table' do
    it { should have_db_column :estimated_size }
    it { should have_db_column :object_id }
    it { should have_db_column :object_type }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:team).optional }
    it { should belong_to(:object).optional }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :estimated_size }
  end

  describe 'Methods' do
    let(:user) { create :user }
    let(:team) { create :team }
    let(:my_module) { create :my_module }
    let(:result) do
      create :result, name: 'test result', my_module: my_module
    end

    let(:result_text) do
      create :result_text, text: '<img data-mce-token=1  src=""/>', result: result
    end
    let(:image) { create :tiny_mce_asset, id: 1, team_id: team.id }

    describe '#update_images' do
      it 'save new image' do
        create :protocol, my_module: result_text.result.my_module
        result_text.result.my_module.protocol.update(team_id: image.team_id)
        TinyMceAsset.update_images(result_text, [Base62.encode(image.id)].to_s, user)
        updated_image = TinyMceAsset.find(image.id)
        expect(updated_image.object_type).to eq 'ResultText'
        expect(ResultText.find(result_text.id).text).not_to include 'fake-path'
      end
    end

    describe '#generate_url' do
      it 'create new url' do
        image.update(object: result_text)
        expect(TinyMceAsset.generate_url(result_text.text, result_text)).to include 'test.jpg'
      end

      it 'restrict acces to image' do
        image
        expect(TinyMceAsset.generate_url(result_text.text, result_text)).not_to include 'test.jpg'
      end
    end

    describe '#reassign_tiny_mce_image_references' do
      it 'change image token in rich text field' do
        new_result_text = result_text
        TinyMceAsset.update_images(new_result_text, [Base62.encode(image.id)].to_s, user)
        create :tiny_mce_asset, id: 2, object: new_result_text
        new_result_text.reassign_tiny_mce_image_references([[1, 2]])
        expect(ResultText.find(new_result_text.id).text).to include 'data-mce-token="2"'
      end
    end
  end
end

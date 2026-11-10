# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorageHelper, type: :helper do
  describe '#image_preview_format' do
    it 'returns jpeg for a jpeg blob' do
      expect(helper.image_preview_format(double('blob', content_type: 'image/jpeg'))).to eq 'jpeg'
    end

    it 'returns jpeg for a jpg blob' do
      expect(helper.image_preview_format(double('blob', content_type: 'image/jpg'))).to eq 'jpeg'
    end

    it 'returns png for any other blob' do
      expect(helper.image_preview_format(double('blob', content_type: 'image/png'))).to eq 'png'
    end

    it 'returns png when there is no blob' do
      expect(helper.image_preview_format(nil)).to eq 'png'
    end
  end
end

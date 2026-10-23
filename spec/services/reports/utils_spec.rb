# frozen_string_literal: true

require 'rails_helper'

describe Reports::Utils do
  describe '.link_prepare' do
    it 'prefixes relative links with the SciNote url' do
      expect(described_class.link_prepare('http://sn.test', '/projects/1')).to eq('http://sn.test/projects/1')
    end

    it 'keeps absolute links untouched' do
      expect(described_class.link_prepare('http://sn.test', 'https://example.com/a')).to eq('https://example.com/a')
    end

    it 'returns the link as is without a SciNote url' do
      expect(described_class.link_prepare('', '/projects/1')).to eq('/projects/1')
      expect(described_class.link_prepare(nil, '/projects/1')).to eq('/projects/1')
    end
  end

  describe '.image_prepare' do
    it 'uses the medium preview for inline assets' do
      asset = Asset.new
      allow(asset).to receive_messages(inline?: true, medium_preview: :medium, large_preview: :large)
      expect(described_class.image_prepare(asset)).to eq(:medium)
    end

    it 'uses the large preview for other assets' do
      asset = Asset.new
      allow(asset).to receive_messages(inline?: false, medium_preview: :medium, large_preview: :large)
      expect(described_class.image_prepare(asset)).to eq(:large)
    end

    it 'uses a png representation for tinymce assets' do
      image = double('image')
      allow(image).to receive(:representation).with(format: :png).and_return(:png_representation)
      tiny_mce_asset = TinyMceAsset.new
      allow(tiny_mce_asset).to receive(:image).and_return(image)
      expect(described_class.image_prepare(tiny_mce_asset)).to eq(:png_representation)
    end

    it 'returns nil for unknown objects' do
      expect(described_class.image_prepare(Object.new)).to be_nil
    end
  end

  describe '.calculate_color_hsp' do
    it 'returns 255 for values that are not a #rrggbb color' do
      expect(described_class.calculate_color_hsp('#fff')).to eq(255)
      expect(described_class.calculate_color_hsp('')).to eq(255)
    end

    it 'returns 0 for black and 255 for white' do
      expect(described_class.calculate_color_hsp('#000000')).to eq(0)
      expect(described_class.calculate_color_hsp('#ffffff')).to be_within(0.001).of(255)
    end

    it 'weights green higher than red and blue' do
      expect(described_class.calculate_color_hsp('#00ff00')).to be > described_class.calculate_color_hsp('#ff0000')
      expect(described_class.calculate_color_hsp('#ff0000')).to be > described_class.calculate_color_hsp('#0000ff')
    end
  end
end

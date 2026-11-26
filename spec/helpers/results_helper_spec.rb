# frozen_string_literal: true

require 'rails_helper'

describe ResultsHelper, type: :helper do
  # Result#is_text / is_table / is_asset raise (deprecated), so these examples
  # use plain doubles that only expose the predicates and related records.
  def result_double(type, record_attrs = {})
    double('Result', { is_text: type == :text, is_table: type == :table, is_asset: type == :asset }.merge(record_attrs))
  end

  let(:created_at) { Time.zone.parse('2026-05-04 09:15') }

  describe '#published_text_for_result' do
    it 'describes a published text result' do
      result = result_double(:text, created_at: created_at)

      expect(helper.published_text_for_result(result)).to eq(
        I18n.t('my_modules.results.published_text', timestamp: I18n.l(created_at, format: :full))
      )
    end

    it 'describes a published table result' do
      result = result_double(:table, created_at: created_at)

      expect(helper.published_text_for_result(result)).to eq(
        I18n.t('my_modules.results.published_table', timestamp: I18n.l(created_at, format: :full))
      )
    end

    it 'describes a published asset result' do
      result = result_double(:asset, created_at: created_at)

      expect(helper.published_text_for_result(result)).to eq(
        I18n.t('my_modules.results.published_asset', timestamp: I18n.l(created_at, format: :full))
      )
    end

    it 'returns nil for an unknown result type' do
      expect(helper.published_text_for_result(result_double(:none, created_at: created_at))).to be_nil
    end
  end

  describe '#edit_result_link' do
    it 'links an asset result to its JSON edit route' do
      asset = double('ResultAsset', to_param: '33')

      expect(helper.edit_result_link(result_double(:asset, result_asset: asset)))
        .to eq edit_result_asset_path(asset, format: :json)
    end

    it 'returns nil for an unknown result type' do
      expect(helper.edit_result_link(result_double(:none))).to be_nil
    end

    # The text and table routes are only nested create/update/destroy routes, so the
    # edit path helpers used by the helper do not exist.
    pending 'bug: edit_result_link raises for text results (no edit route for result texts)' do
      text = double('ResultText', to_param: '11')

      expect { helper.edit_result_link(result_double(:text, result_text: text)) }.not_to raise_error
    end

    pending 'bug: edit_result_link raises for table results (no edit route for result tables)' do
      table = double('ResultTable', to_param: '22')

      expect { helper.edit_result_link(result_double(:table, result_table: table)) }.not_to raise_error
    end
  end

  describe '#result_path_of_type' do
    it 'links an asset result to its asset route' do
      asset = double('ResultAsset', to_param: '33')

      expect(helper.result_path_of_type(result_double(:asset, result_asset: asset))).to eq result_asset_path(asset)
    end

    it 'returns nil for an unknown result type' do
      expect(helper.result_path_of_type(result_double(:none))).to be_nil
    end

    # result_text_path / result_table_path resolve to nested routes that need a result id.
    pending 'bug: result_path_of_type raises for text results (no show route for result texts)' do
      text = double('ResultText', to_param: '11')

      expect { helper.result_path_of_type(result_double(:text, result_text: text)) }.not_to raise_error
    end

    pending 'bug: result_path_of_type raises for table results (no show route for result tables)' do
      table = double('ResultTable', to_param: '22')

      expect { helper.result_path_of_type(result_double(:table, result_table: table)) }.not_to raise_error
    end
  end

  describe '#edit_result_button_class' do
    it 'returns the button class for each result type' do
      expect(helper.edit_result_button_class(result_double(:asset))).to eq 'edit-result-asset'
      expect(helper.edit_result_button_class(result_double(:text))).to eq 'edit-result-text'
      expect(helper.edit_result_button_class(result_double(:table))).to eq 'edit-result-table'
    end

    it 'returns nil for an unknown result type' do
      expect(helper.edit_result_button_class(result_double(:none))).to be_nil
    end
  end

  describe '#result_icon_class' do
    it 'returns the tables icon for every result' do
      expect(helper.result_icon_class(result_double(:text))).to eq 'sn-icon sn-icon-tables'
      expect(helper.result_icon_class(result_double(:asset))).to eq 'sn-icon sn-icon-tables'
    end
  end
end

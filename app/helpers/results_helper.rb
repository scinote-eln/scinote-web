# frozen_string_literal: true

module ResultsHelper
  def published_text_for_result(result)
    if result.is_text
      t('my_modules.results.published_text', timestamp: l(result.created_at, format: :full))
    elsif result.is_table
      t('my_modules.results.published_table', timestamp: l(result.created_at, format: :full))
    elsif result.is_asset
      t('my_modules.results.published_asset', timestamp: l(result.created_at, format: :full))
    end
  end

  def edit_result_link(result)
    if result.is_text
      edit_result_text_path(result.result_text, format: :json)
    elsif result.is_table
      edit_result_table_path(result.result_table, format: :json)
    elsif result.is_asset
      edit_result_asset_path(result.result_asset, format: :json)
    end
  end

  def result_path_of_type(result)
    if result.is_asset
      result_asset_path(result.result_asset)
    elsif result.is_text
      result_text_path(result.result_text)
    elsif result.is_table
      result_table_path(result.result_table)
    end
  end

  def edit_result_button_class(result)
    if result.is_asset
      'edit-result-asset'
    elsif result.is_text
      'edit-result-text'
    elsif result.is_table
      'edit-result-table'
    end
  end

  def result_icon_class(result)
    return 'fas fa-table' unless result

    if result.is_asset
      'fas fa-paperclip'
    elsif result.is_text
      'fas fa-font'
    elsif result.is_table
      'fas fa-table'
    else
      # just return table for any other result
      'fas fa-table'
    end
  end
end

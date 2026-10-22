export const TYPE_LABEL_KEYS = {
  RepositoryTextValue: 'repository_text_value',
  RepositoryNumberValue: 'repository_number_value',
  RepositoryAssetValue: 'repository_asset_value',
  RepositoryListValue: 'repository_list_value',
  RepositoryChecklistValue: 'repository_checklist_value',
  RepositoryStatusValue: 'repository_status_value',
  RepositoryStockValue: 'repository_stock_value',
  RepositoryDateValue: 'repository_date_value',
  RepositoryDateRangeValue: 'repository_date_range_value',
  RepositoryTimeValue: 'repository_time_value',
  RepositoryTimeRangeValue: 'repository_time_range_value',
  RepositoryDateTimeValue: 'repository_date_time_value',
  RepositoryDateTimeRangeValue: 'repository_date_time_range_value'
};

// Base (non-range) data types selectable from the "Column type" picker when adding/editing a column.
export const CREATABLE_TYPES = [
  'RepositoryTextValue',
  'RepositoryNumberValue',
  'RepositoryAssetValue',
  'RepositoryListValue',
  'RepositoryChecklistValue',
  'RepositoryStatusValue',
  'RepositoryDateValue',
  'RepositoryTimeValue',
  'RepositoryDateTimeValue'
];

export function typeLabel(i18n, dataType) {
  const key = TYPE_LABEL_KEYS[dataType];
  return key ? i18n.t(`libraries.manange_modal_column.select.${key}`) : null;
}

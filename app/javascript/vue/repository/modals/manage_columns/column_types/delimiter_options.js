// Mirrors Constants::REPOSITORY_LIST_ITEMS_DELIMITERS_MAP / _ICON_MAP (config/initializers/constants.rb)
export const DELIMITER_CHARS = { auto: '\n', return: '\n', comma: ',', semicolon: ';', space: ' ' };
export const DELIMITER_ICONS = { auto: '＊', return: '↵', comma: ',', semicolon: ';', space: '⎵' };

export function delimiterOptions(i18n) {
  return Object.keys(DELIMITER_CHARS).map((key) => (
    [key, i18n.t(`libraries.manange_modal_column.list_type.delimiters.${key}`), { icon: DELIMITER_ICONS[key] }]
  ));
}

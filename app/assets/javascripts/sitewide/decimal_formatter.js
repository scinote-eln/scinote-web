/* eslint-disable no-unused-vars */

function formatDecimalValue(value, decimals) {
  let decimalValue = value.replace(/[^-0-9.]/g, '');
  if (decimals === 0) {
    return decimalValue.split('.')[0];
  }
  return decimalValue.match(new RegExp(`^-?\\d*(\\.\\d{0,${decimals}})?`))[0];
}

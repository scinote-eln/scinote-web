/* eslint-disable no-unused-vars */

function hex2a(hexx) {
  const hexString = hexx.toString(); // Force conversion
  let asciiString = '';
  for (let i = 0; i < hexString.length; i += 2) {
    asciiString += String.fromCharCode(parseInt(hexString.substr(i, 2), 16));
  }
  return asciiString;
}

function getMetadataCellValue(jsonData, row, col) {
  if (jsonData == null) return '';

  const key = `${row}:${col}`;
  for (let i = 0; i < jsonData.length; i += 1) {
    const item = jsonData[i];
    const itemKey = `${item.row}:${item.col}`;
    if (itemKey === key) {
      return item.className;
    }
  }
  return null;
}

function generateElnTable(content, tableMetadata) {
  function colName(n) {
    const asciiA = 'A'.charCodeAt(0);
    const asciiZ = 'Z'.charCodeAt(0);
    const len = (asciiZ - asciiA) + 1;
    let name = '';
    while (n >= 0) {
      name = String.fromCharCode((n % len) + asciiA) + name;
      n = Math.floor(n / len) - 1;
    }
    return name;
  }

  const decodedContent = hex2a(content);
  const tableData = JSON.parse(decodedContent);
  const numRows = tableData.data.length + 1;
  const numCols = tableData.data[0].length + 1;

  let tableRows = '';

  for (let i = 0; i < numRows; i += 1) {
    let tableCells = '';

    for (let j = 0; j < numCols; j += 1) {
      let cellData = '';
      let cellClass = tableMetadata ? getMetadataCellValue(tableMetadata.cells, i - 1, j - 1) : '';

      if (i > 0 && j > 0 && tableData.data[i - 1][j - 1] !== null) {
        cellData = tableData.data[i - 1][j - 1];
      } else if (i === 0 && j !== 0) {
        cellData = tableMetadata && tableMetadata.plateTemplate ? j.toString() : colName(j - 1);
      } else if (j === 0 && i !== 0) {
        cellData = tableMetadata && tableMetadata.plateTemplate ? colName(i - 1) : i.toString();
      }

      tableCells = `${tableCells}<td ${cellClass ? `class="${cellClass}"` : ''}>${cellData}</td>`;
    }

    tableRows = `${tableRows}<tr>${tableCells}</tr>`;
  }

  return $.parseHTML(`<table class="table table-bordered eln-table"><tbody>${tableRows}</tbody></table>`);
}

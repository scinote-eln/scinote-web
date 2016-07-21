function hex2a(hexx) {
  var hex = hexx.toString(); // Force conversion
  var str = "";
  for (var i = 0; i < hex.length; i += 2) {
    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
  }
  return str;
}

function generateElnTable(id, content) {
  /*********************************************/
  /* INNER FUNCTIONS                           */
  /*********************************************/
  function colName(n) {
    var ordA = "A".charCodeAt(0);
    var ordZ = "Z".charCodeAt(0);
    var len = ordZ - ordA + 1;

    var s = "";
    while(n >= 0) {
      s = String.fromCharCode(n % len + ordA) + s;
      n = Math.floor(n / len) - 1;
    }
    return s;
  }

  /*********************************************/
  /* ACTUAL FUNCTION CODE                      */
  /*********************************************/
  var txt = hex2a(content);
  var jstr = JSON.parse(txt);

  var rows = jstr.data.length + 1;
  var cols = jstr.data[0].length + 1;

  var str = rows + "|" + cols;

  var html_s = "<table class='table table-bordered eln-table'><tbody>";
  var html_e = "</tbody></table>";

  var tr = "";
  for (var i = 0; i < rows; i++) {
    var tr_s = "<tr>";
    var th = "";
    var d = "";
    var d_str = "";
    for (var j = 0; j < cols; j++) {
      if ((i > 0) && (j > 0)) {
        if (jstr.data[i - 1][j - 1] !== null) {
          d = jstr.data[i - 1][j - 1];
          d_str = "<td>" + d;
        } else {
          d = "";
          d_str = "<td>" + d;
        }
      } else {
        if ((i == 0) && (j == 0)) {
          d = "";
          d_str = "<td>" + d;
        } else if (i == 0) {
          d = colName(j - 1);
          d_str = "<td>" + d;
        } else {
          d = i.toString();
          d_str = "<td style='width: 60px;'>" + d;
        }
      }

      th = th + d_str + "</td>";
    }
    var tr_e = "</tr>";
    tr = tr + tr_s + th + tr_e;
  }
  var html = html_s + tr + html_e;
  return $.parseHTML(html);
}
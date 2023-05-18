/* eslint-disable no-unused-vars, no-use-before-define */

var tableColRowName = (function() {
  function tableColHeaders(isPlateTemplate) {
    if (isPlateTemplate) {
      return function(visualColumnIndex) {
        return visualColumnIndex + 1;
      };
    }

    return true;
  }

  function tableRowHeaders(isPlateTemplate) {
    if (isPlateTemplate) {
      return function(visualColumnIndex) {
        var ordA = 'A'.charCodeAt(0);
        var ordZ = 'Z'.charCodeAt(0);
        var len = (ordZ - ordA) + 1;
        var num = visualColumnIndex;

        var colName = '';
        while (num >= 0) {
          colName = String.fromCharCode((num % len) + ordA) + colName;
          num = Math.floor(num / len) - 1;
        }
        return colName;
      };
    }

    return true;
  }

  return {
    tableColHeaders: function(isPlateTemplate) {
      return tableColHeaders(isPlateTemplate);
    },
    tableRowHeaders: function(isPlateTemplate) {
      return tableRowHeaders(isPlateTemplate);
    }
  };
}());

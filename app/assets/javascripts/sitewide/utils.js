// Converts JSON data received from the server
// to flat array of values
function jsonToValuesArray(jsonData) {
  errMsgs =[];
  for (var key in jsonData) {
  	var values = jsonData[key];
		$.each(values, function(idx, val) {
		  errMsgs.push(val);
		});
  }
  return errMsgs;
}

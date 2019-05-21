/**
* @author Tamas Vertse
* @Copyright 1998-2017 ChemAxon Ltd.
*/
(function() {
	
	var open = /^\s*<\w+/;
	var close = /(\/|<\/\w+)\s*>\s*$/;

	function xmlindent(xml) {
		var lines = tokenize(xml);
		var n = lines.length;
		var indent = 0;
		var result = "";
		for(var i = 0; i < n; i++) {
			var line = lines[i];
			var diff = 0;
			if(open.test(line)) {
				diff += 1;
			}
			if(close.test(line)) {
				diff -= 1;
			}
			if(diff == -1) {
				result += leftIndent(--indent, line);
			} else {
				result += leftIndent(indent, line);
				indent += diff;
			}
		}
		return result;
	}
	
	function tokenize(xml) {
		var reg = /[^\]]><[^\!]/;
		var end = xml.search(reg)+2;
		var s = xml;
		var tokens = new Array();
		while(end > 1) {
			var next = s.slice(0, end);
			tokens.push(next);
			s = s.substring(end);
			end = s.search(reg)+2;	
		}
		tokens.push(s);
		return tokens;
	}
	
	function leftIndent(n, s) {		
		var result = s + '\n'; 
		return (n > 0)? ' '.repeat(n*2)+result : result;
	}

	window.xmlindent = xmlindent;
})();
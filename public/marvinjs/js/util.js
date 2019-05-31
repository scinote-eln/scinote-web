(function (win, doc) {

	"use strict";

	function Promise () {
		this.success		= false;
		this.doneCallbacks 	= [];
		this.failCallbacks 	= [];
		this.thenCallbacks 	= [];
	}

	Promise.prototype.done = function done (cb) {
		if (typeof cb == "undefined") return this;
		this.doneCallbacks.push(cb);
		return this;
	}

	Promise.prototype.fail = function fail (cb) {
		if (typeof cb == "undefined") return this;
		this.failCallbacks.push(cb);
		return this;
	}

	Promise.prototype.then = function then (cb) {
		if (typeof cb == "undefined") return this;
		this.thenCallbacks.push(cb);
		return this;
	}

	Promise.prototype.resolve = function resolve () {
		this.success = true;
		this.callThem(this.doneCallbacks);
		this.callThem(this.thenCallbacks);
	}

	Promise.prototype.resolveWith = function resolveWith () {
		this.success = true;
		this.callThem(this.doneCallbacks, arguments);
		this.callThem(this.thenCallbacks);
	}

	Promise.prototype.reject = function reject () {
		this.callThem(this.failCallbacks);
		this.callThem(this.thenCallbacks);
	}

	Promise.prototype.rejectWith = function rejectWith () {
		this.callThem(this.failCallbacks, arguments);
		this.callThem(this.thenCallbacks);
	}

	Promise.prototype.callThem = function callThem (cbArray, cbArgs) {
		var argumentsPresent = true;
		if (typeof cbArgs == "undefined") {
			argumentsPresent = false;
		}

		var l = cbArray.length,
			i = 0;

		for (i; i < l; i++) {
			if (argumentsPresent) {
				cbArray[i].apply(this, cbArgs);
			} else {
				cbArray[i].call(this);
			}
		}
	}

	//win.Promise = Promise;

	function _getIframe (id) {
		var re = new RegExp(/^#.*/);
		if (typeof id !== "string") {
			return null;
		}
		// remove hashmark if present
		return document.getElementById( (re.test(id)) ? id.substr(1) : id );
	}

	function _getPackage (iframeElement) {
		if (typeof iframeElement.contentWindow.marvin != "undefined") {
			return iframeElement.contentWindow.marvin;
		}
		return null;
	}

	win.getMarvinPackage = function getMarvinPackage (iframeID) {
		var p = new Promise(),
			iframeElement = _getIframe(iframeID);

		if (iframeElement == null) {
			setTimeout(function () {
				p.rejectWith("Unable to get iframe with id: " + iframeID);
			});
			return p;
		}

		var marvinPackage = _getPackage(iframeElement);
		if (marvinPackage) {
			setTimeout(function () {
				p.resolveWith(marvinPackage);
			});
		} else { // use listener
			iframeElement.addEventListener("load", function handleSketchLoad (e) {
				var marvin = _getPackage(iframeElement);
				if (marvin) {
					p.resolveWith(marvin);
				} else {
					p.rejectWith("Unable to find marvin package in iframe with id : " + iframeID);
				}
			});
 		}

		return p;
	}

	win.getMarvinPromise = function getMarvinPromise (iframeID) {

		var p = new Promise(),
			iframeLoadedFlag,
			iframeElement = _getIframe(iframeID),
			sketcherInstance;

		if (iframeElement == null) {
			setTimeout(function () {
				p.rejectWith("Unable to get iframe with id: " + iframeID);
			});
			return p;
		}

		// fail if iframe not present with specified id
		if (iframeElement == null) {
			var errorMessage = "Unable to find iframe with ID: " + iframeID;
			setTimeout(function delayPromiseRejection () {
				p.rejectWith(errorMessage);
			});
			return p;
		}

		var marvinPackage = _getPackage(iframeElement);
		if (marvinPackage) {
			marvinPackage.onReady(function() {
				if (typeof marvinPackage.sketcherInstance != "undefined") {
					setTimeout(function delayPromiseResolve () {
						p.resolveWith(_getPackage(iframeElement).sketcherInstance);
					});
					return p;
				} else {
					setTimeout(function delayPromiseRejection () {
						p.rejectWith("Unable to find sketcherInstance in iframe with id: " + iframeID);
					});
					return p;
				}
			});
		} else { // use listener
			iframeElement.addEventListener("load", function handleSketchLoad (e) {
				var marvin = _getPackage(iframeElement);
				if (marvin) {
					marvin.onReady(function() {
						if (typeof marvin.sketcherInstance != 'undefined') {
							p.resolveWith(marvin.sketcherInstance);
						} else {
							p.rejectWith("Unable to find sketcherInstance in iframe with id: " + iframeID);
						}
					});
				} else {
					p.rejectWith("Unable to find marvin package, cannot retrieve sketcher instance");
				}

			});
 		}

		return p;
	}

}(window, document))

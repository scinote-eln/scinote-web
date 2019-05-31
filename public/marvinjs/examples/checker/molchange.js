
/* Notify about molchange events and provides the mol source of the new structure. */
var MolChangeHandler = (function() {

	function createEvent(sketcher) {
		return {
			date: new Date(),
			target: sketcher,
			isDeprecated: false
		}
	}
	
	// purge event queue (deactivate events that found there)
	function reset(eventQueue) {
		for(var i = 0; i < eventQueue.length; i++) {
			eventQueue[i].isDeprecated = true;
		}
		eventQueue = [];
	}
	
	var DELAY = 1000;
	
	/*
	 * Constructor of MolChangeHandler.
	 * @param bind to this Marvin JS editor instance
	 * @param triggered function at molchange event.
	 * */
	function MolChangeHandler(sketcher, onSuccess) {
		this.sketcher = sketcher;
		this.onSuccess = onSuccess;
		this.pending = false;
		this.eventQueue = [];
		var that = this;
		this.sketcher.on('molchange', function() {
			onMolChange(that);
		});
	}
	
	// wait to aggregate molchange events
	function onMolChange(that) {
		if(!that.pending) {
			that.pending = true;
			setTimeout(function() {
				that.pending = false;
				fireEvent(that);
			}, DELAY);
		}
	}
	
	// trigger a new event
	function fireEvent(that){
			var e = createEvent(that.sketcher);
			reset(that.eventQueue);
			that.eventQueue.push(e);
			var callback = that.onSuccess;
			callback(e);
	}
	
	return MolChangeHandler;
}());


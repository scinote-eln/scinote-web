/*
 * Scroll to and focus on element.
 */
function goToFormElement(input) {
	$("html, body").stop();
	$("html, body").animate(
		{
		  scrollTop: $(input).closest(".form-group").offset().top
		    - ($(".navbar-fixed-top").outerHeight(true)
		      + $(".navbar-secondary").outerHeight(true)
		      + $(".alert-dismissable").outerHeight(true))
		},
		"slow",
		function() { $(input).focus(); }
	);
}

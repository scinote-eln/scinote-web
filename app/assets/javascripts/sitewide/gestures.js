// Scroll to and focus on element
function goToFormElement(el) {
	$("html, body").animate(
		{
		  scrollTop: $(el).closest(".form-group").offset().top
		    - ($(".navbar-fixed-top").outerHeight(true)
		      + $(".navbar-secondary").outerHeight(true)
		      + $(".alert-dismissable").outerHeight(true))
		},
		"slow",
		function() { $(el).focus(); }
	);
}
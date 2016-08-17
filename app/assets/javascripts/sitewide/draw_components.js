/*
 * By adding unique attribute to image's src, we
 * force browser to reload/update cached image
 * (useful for AJAX calls).
 */
function reloadImages(imgs) {
	_.each(imgs, function (img) {
		var src = $(img).attr("src");
		src = src.split("?", 1);
		src += "?timestamp="  + new Date().getTime();
		$(img).attr("src", src);
	});
}

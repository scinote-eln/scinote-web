// By adding unique attribute to image's src,
// we force browser to reload/update cached image
function reloadImage(img) {
	var src = $(img).attr("src");
	src = src.split("?", 1);
	src += "?timestamp="  + new Date().getTime();
	$(img).attr("src", src);
}

// Hack for image retrieval after upload (403 is
// thrown, mostly Chrome issue, and hence image
// isn't retrieved)
function reloadImagesHack(imgs) {
  setTimeout(function() {
		if(imgs.length) {
			imgs.each(function() {
			  reloadImage($(this));
			});
		}
  }, 1000);
}

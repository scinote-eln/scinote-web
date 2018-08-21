(function() {
  'use strict';

  $(".tree li.parent_li ").find("> span i").on("click", function (e) {
    e.stopPropagation();
    var el = $(this).closest("li.parent_li");

    if (el.find(" > ul.accountNavigation").is(":visible")) {
      el.find(" > span > i.triangleDown").hide();
      el.find(" > span > i.triangleRight").show();
      el.find(" > ul.accountNavigation").hide();
    } else {
      el.find(" > span > i.triangleDown").show();
      el.find(" > span > i.triangleRight").hide();
      el.find(" > ul.accountNavigation").show();
    }
  });
})();

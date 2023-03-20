var CounterBadge = (function() {
  'use strict';

  function updateCounterBadge(count, linkedId, type) {
    var badge =
      $('.' + type +
        '-badge-indicator[data-linked-id="' +
        linkedId + '"]').first();
    if (badge.length) {
      badge.text(count);
      if (count > 0) {
        badge.removeClass('hidden');
      } else {
        badge.addClass('hidden');
      }
    }
  }

  return {
    updateCounterBadge: updateCounterBadge
  };
})();

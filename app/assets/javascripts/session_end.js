/* globals I18n */

(function() {
  'use strict';

  var originalTitle = '';
  var expireIn;
  var expireLimit = 900; // 15min
  var timeoutID;
  var expirationUrl = $('meta[name=\'expiration-url\']').attr('content');

  var pad = function(i) {
    var s = ('0' + Math.floor(i));
    return s.substring(s.length - 2);
  };

  var newTimerStr = function(expirationTime) {
    var m = (expirationTime / 60) % 60;
    var s = (expirationTime % 60);
    return [m, s].map(pad).join(':');
  };

  function getSessionEnd() {
    if (expirationUrl) {
      $.get(expirationUrl, function(data) {
        if (data <= 0) {
          $('#session-finished').modal();
        } else if (data <= expireLimit + 1) {
          expireIn = data;
          originalTitle = document.title;
          // eslint-disable-next-line no-use-before-define
          timeoutID = setTimeout(expirationInTime, 1000);
        } else {
          timeoutID = setTimeout(getSessionEnd, (data - expireLimit) * 1000);
        }
      });
    }
  }

  function expirationInTime() {
    var timeString;
    if (expireIn > 0) {
      timeString = newTimerStr(expireIn);
      document.title = timeString + ' ' + String.fromCodePoint(0x1F62A) + ' ' + originalTitle;
      $('.expiring').text(I18n.t('devise.sessions.expire_modal.session_end_in.header', { time: timeString }));
      expireIn -= 1;
      if (!$('#session-expire').hasClass('in')) {
        $('#session-expire').modal().off('hide.bs.modal').on('hide.bs.modal', function() {
          if (expireIn > 0) {
            $.post($('meta[name=\'revive-url\']').attr('content'));
            document.title = originalTitle;
            clearTimeout(timeoutID);
            timeoutID = setTimeout(getSessionEnd, 1000);
          }
        });
      }
      timeoutID = setTimeout(expirationInTime, 1000);
    } else {
      document.title = originalTitle;
      $('#session-expire').modal('hide');
      $('#session-finished').modal();
    }
  }
  timeoutID = setTimeout(getSessionEnd, 1000);

  $(document).on('click', '.session-login', function() {
    window.location.reload();
  });
}());

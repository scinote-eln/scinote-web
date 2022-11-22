/* globals I18n */

(function() {
  'use strict';

  var expireOn;
  var timeoutID;
  const oneSecondTimeout = 1000;
  const expireLimit = 900000; // 15min in miliseconds

  function padTimeStr(i) {
    var s = ('0' + Math.floor(i));
    return s.substring(s.length - 2);
  }

  function newTimerStr(expirationTime) {
    var m = (expirationTime / 60) % 60;
    var s = (expirationTime % 60);
    return [m, s].map(padTimeStr).join(':');
  }

  function getCurrentTime() {
    var dateNow = new Date();
    return dateNow.getTime();
  }

  function sessionExpireIn() {
    expireOn = window.localStorage.getItem('sessionEnd');
    return expireOn - getCurrentTime();
  }

  function setSessionTimeout(functionCallback, timeoutTime) {
    if (timeoutID) {
      clearTimeout(timeoutID);
    }
    timeoutID = setTimeout(functionCallback, timeoutTime);
  }

  function toogleDocumentTitle(timeString = null) {
    var sleepEmoticon = String.fromCodePoint(0x1F62A);
    var originalTitle = document.title.split(sleepEmoticon).pop().trim();

    if (timeString) {
      document.title = timeString + ' ' + sleepEmoticon + ' ' + originalTitle;
    } else {
      document.title = originalTitle;
    }
  }

  function initializeSessionCountdown() {
    var expirationUrl = $('meta[name=\'expiration-url\']').attr('content');
    var expireIn;
    if (expirationUrl) {
      $.get(expirationUrl, function(data) {
        expireOn = Math.max(window.localStorage.getItem('sessionEnd'), getCurrentTime() + parseInt(data, 10));
        window.localStorage.setItem('sessionEnd', expireOn);
        expireIn = sessionExpireIn();

        if (expireIn <= 0) {
          $('#session-finished').modal();
        } else if (expireIn <= expireLimit + oneSecondTimeout) {
          // eslint-disable-next-line no-use-before-define
          setSessionTimeout(sessionCountdown, oneSecondTimeout);
        } else {
          setSessionTimeout(initializeSessionCountdown, (expireIn - expireLimit));
        }
      });
    }
  }

  function reviveSession() {
    $.post($('meta[name=\'revive-url\']').attr('content'));
    toogleDocumentTitle();
    window.localStorage.removeItem('sessionEnd');
    setSessionTimeout(initializeSessionCountdown, oneSecondTimeout);
  }

  function initializeSessionReviveCallbacks() {
    $('#session-expire').modal().off('hide.bs.modal').on('hide.bs.modal', function() {
      if (sessionExpireIn() > 0) {
        reviveSession();
      }
    });

    // for manual page reload
    $(window).off('beforeunload').on('beforeunload', function() {
      if (sessionExpireIn() > 0) {
        reviveSession();
      }
    });
  }

  function sessionCountdown() {
    var timeString;
    var expireIn = sessionExpireIn();

    if (!expireOn) {
      initializeSessionCountdown();
    } else if (expireIn > 0 && expireIn <= expireLimit) {
      timeString = newTimerStr(expireIn / 1000);
      toogleDocumentTitle(timeString);
      $('.expiring').text(I18n.t('devise.sessions.expire_modal.session_end_in.header', { time: timeString }));

      if (!$('#session-expire').hasClass('in')) {
        initializeSessionReviveCallbacks();
      }

      setSessionTimeout(sessionCountdown, oneSecondTimeout);
    } else if (expireIn <= 0) {
      toogleDocumentTitle();
      $('#session-expire').modal('hide');
      $('#session-finished').modal();
    }
  }


  window.localStorage.removeItem('sessionEnd');
  setSessionTimeout(initializeSessionCountdown, oneSecondTimeout);

  $(document).on('click', '.session-login', function() {
    window.location.reload();
  });

  $(window).on('storage', (event) => {
    if (event.originalEvent.storageArea !== localStorage) return;
    if (event.originalEvent.key === 'sessionEnd') {
      if (!expireOn && event.originalEvent.newValue) {
        if ($('#session-finished').hasClass('in')) {
          $('#session-finished').modal('hide');
        }
        setSessionTimeout(initializeSessionCountdown, oneSecondTimeout);
      } else if (expireOn && !event.originalEvent.newValue) {
        toogleDocumentTitle();
      }

      expireOn = event.originalEvent.newValue;
      $('#session-expire').modal().off('hide.bs.modal').modal('hide');
    }
  });
}());

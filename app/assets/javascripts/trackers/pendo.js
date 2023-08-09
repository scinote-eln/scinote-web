/* eslint-disable no-multi-assign */
/* eslint-disable no-param-reassign */
/* eslint-disable no-underscore-dangle */

(function() {
  const pendoInitElem = document.getElementById('pendo-js-script');
  const visitorId = pendoInitElem.getAttribute('data-visitor-id').trim();
  const visitorUserEmail = pendoInitElem.getAttribute('data-visitor-user-email').trim();
  const visitorUserId = pendoInitElem.getAttribute('data-visitor-user-id');
  const accountId = pendoInitElem.getAttribute('data-account-id').trim();
  const apiKey = pendoInitElem.getAttribute('data-api-key').trim();

  (function(p, e, n, d) {
    var v;
    var w;
    var x;
    var y;
    var z;
    var o = p[d] = p[d] || {};
    o._q = o._q || [];
    v = ['initialize', 'identify', 'updateOptions', 'pageLoad', 'track']; for (w = 0, x = v.length; w < x; w += 1) {
      (function(m) {
        o[m] = o[m] || function() { o._q[m === v[0] ? 'unshift' : 'push']([m].concat([].slice.call(arguments, 0))); };
      }(v[w]));
    }
    y = e.createElement(n);
    y.async = true;
    y.src = `https://content.product-analytics.scinote.net/agent/static/${apiKey}/pendo.js`;
    y.nonce = document.querySelector('meta[name="csp-nonce"]').getAttribute('content');
    z = e.getElementsByTagName(n)[0]; z.parentNode.insertBefore(y, z);
  }(window, document, 'script', 'pendo'));
  window.pendo.initialize({
    visitor: {
      id: visitorId,
      email: visitorUserEmail,
      userID: visitorUserId
    },
    account: {
      id: accountId
    }
  });
}());

/* eslint-enable no-multi-assign */
/* eslint-enable no-param-reassign */
/* eslint-enable no-underscore-dangle */

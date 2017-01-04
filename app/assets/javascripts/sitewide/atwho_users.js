(function() {
  'use strict';

  $(document).on(
    'focus',
    '[data-atwho-users-edit]',
    function() {
      if (_.isUndefined($(this).data('atwho'))) {
        $(this)
        .atwho({
          at: '@',
          callbacks: {
            remoteFilter: function(query, callback) {
              $.getJSON(
                '/organizations/1/atwho_users.json',
                {query: query},
                function(data) {
                  callback(data.users);
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = '';
                res += '<li class="atwho-li atwho-li-user">';
                res += '<img src="' + map.img_url + '" height="20" width="20" />';
                res += '&nbsp;';
                res += '<span data-full-name>';
                res += map.full_name;
                res += '</span>';
                res += '&nbsp;';
                res += '<i class="fa fa-circle" aria-hidden="true"></i>';
                res += '&nbsp;';
                res += '<small data-email>';
                res += map.email;
                res += '</small>';
                res += '</li>';
              } catch (_error) {
                res = '';
              }
              return res;
            },
            highlighter: function(li, query) {
              var li2 = $(li);
              li2.addClass('highlighted');
              var prevVal =
                li2
                .find('[data-full-name]')
                .html();
              var newVal =
                prevVal
                .replace(query, '<strong>' + query + '</strong>');
              li2.find('[data-full-name]').html(newVal);
              prevVal =
                li2
                .find('[data-email]')
                .html();
              newVal =
                prevVal
                .replace(query, '<strong>' + query + '</strong>');
              li2.find('[data-email]').html(newVal);
              return li2.html();
            }
          },
          insertTpl: '[${atwho-at}${full_name}~${id}]',
          limit: 5,
          startWithSpace: true
        });
      }
    });
})();

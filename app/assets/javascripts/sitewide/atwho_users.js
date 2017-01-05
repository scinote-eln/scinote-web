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
            matcher: function(flag, subtext, should_startWithSpace, acceptSpaceBar) {
              var _a, _y, match, regexp, space;
              flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
              if (should_startWithSpace) {
                flag = '(?:^|\\s)' + flag;
              }
              _a = decodeURI("%C3%80");
              _y = decodeURI("%C3%BF");
              space = ' \xa0'; // Use space...
              regexp = new RegExp(flag + "([A-Za-z" + _a + "-" + _y + "0-9_" + space + "\'\.\+\-]*)$|" + flag + "([^\\x00-\\xff]*)$", 'gi');
              match = regexp.exec(subtext);
              if (match) {
                return match[2] || match[1]
              } else {
                return null;
              }
            },
            remoteFilter: function(query, callback) {
              $.getJSON(
                '/organizations/1/atwho_users.json',
                {query: query},
                function(data) {
                  callback(data.users);
                }
              );
            },
            sorter: function(query, items, _searchKey) {
              // Sorting is already done on server-side
              return items;
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = '';
                res += '<li class="atwho-li atwho-li-user" ';
                res += 'data-id="' + map.id + '" ';
                res += 'data-full-name="' + map.full_name + '">';
                res += '<img src="' + map.img_url + '" class="avatar" />';
                res += '<span data-val="full-name">';
                res += map.full_name;
                res += '</span>';
                res += '<small>';
                res += '&nbsp;';
                res += '&#183;';
                res += '&nbsp;';
                res += '<span data-val="email">';
                res += map.email;
                res += '</span>';
                res += '</small>';
                res += '</li>';
              } catch (_error) {
                res = '';
              }
              return res;
            },
            highlighter: function(li, query) {
              if (!query) {
                return li;
              }

              var li2 = $(li);
              var re = new RegExp(query, 'gi');
              var prevVal =
                li2
                .find('[data-val=full-name]')
                .html();
              var newVal =
                prevVal
                .replace(re, '<strong>$&</strong>');
              li2.find('[data-val=full-name]').html(newVal);
              prevVal =
                li2
                .find('[data-val=email]')
                .html();
              newVal =
                prevVal
                .replace(re, '<strong>$&</strong>');
              li2.find('[data-val=email]').html(newVal);
              return li2[0].outerHTML;
            },
            beforeInsert: function(value, li) {
              var res = '';
              res += '[@' + li.attr('data-full-name');
              res += '~' + li.attr('data-id') + ']';
              return res;
            }
          },
          limit: 5,
          startsWithSpace: true
        });
      }
    });
})();

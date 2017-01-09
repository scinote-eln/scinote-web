(function() {
  'use strict';

  // utilities
  var Util = (function() {
    // helper method that binds show/hidden action
    function showHideBinding() {
      $.each(['show', 'hide'], function (i, ev) {
        var el = $.fn[ev];
        $.fn[ev] = function () {
          this.trigger(ev);
          return el.apply(this, arguments);
        };
      });
    }

    var publicApi = {
      showHideBinding: showHideBinding
    };

    return publicApi;
  })();

  function smartAnnotation(field) {

    // helper methods for AtWho callback
    function _templateEval(_tpl, map) {
      var res;
      try {
        res = generateTemplate(map);
      } catch (_error) {
        res = '';
      }
      return res;
    }

    function _matchHighlighter(li, query) {
      var re, li2, prevVal, newVal;
      if (!query) {
        return li;
      }
      li2 = $(li);
      re = new RegExp(query, 'gi');
    prevVal =
        li2
        .find('[data-val=name]')
        .html();
      newVal =
        prevVal
        .replace(re, '<strong>$&</strong>');
      li2.find('[data-val=name]').html(newVal);
      newVal =
        prevVal
        .replace(re, '<strong>$&</strong>');
      li2.find('[data-val=email]').html(newVal);
      return li2[0].outerHTML;
    }

    function _genrateInputTag(value, li) {
      var res = '';
      res += '[#' + li.attr('data-name');
      res += '~' + li.attr('data-type');
      res += '~' + li.attr('data-id') + ']';
      return res;
    }

    // check if query has some hits and disables the buttons without it
    function resourcesChecker(query, search_filter) {
      debugger;
      var src_btn;
      switch (search_filter) {
        case 'task#':
          src_btn = 'tsk';
          break;
        case 'project#':
          src_btn = 'prj';
          break;
        case 'experiment#':
          src_btn = 'exp';
          break;
        default:
          src_btn = 'sam';
          break;
      }
      $.getJSON(
        '/organizations/1/atwho_menu_items',
        {query: query},
        function(data){
          if(data) {
            _.each($('.atwho-header .btn'), function(el) {
              if(data[$(el).data('filter')].length === 0) {
                $(el).prop('disabled', true);
                $(el)
                  .removeClass('btn-primary')
                  .addClass('btn-default');
                $('[data-filter="' + src_btn +'"]')
                  .removeClass('btn-default')
                  .addClass('btn-primary');
              } else {
                $(el).prop('disabled', false);
              }
            });
          }
        });
    }

    // reset the dropdown
    function reinitializeOnListHide() {
      Util.showHideBinding();

      _.map($('.atwho-view'), function(el) {
        $(el).off('hide');
        $(el).on('hide', function() {
          $(field).atwho('destroy');
          init();
        });
      });
    }

    // Initialize filter buttons
    function initButtons(query, search_filter) {
      $('.atwho-header button').off();

      resourcesChecker(query, search_filter);
      $('.atwho-header button').on('click', function(e) {
        var $button, $prevButton;
        e.stopPropagation();
        $('.atwho-header button').off();
        $button = $(this);
        $prevButton = $button.closest('.atwho-header').children('.btn-primary');

        switch ($button.attr('data-filter')) {
          case 'prj':
            generateNewQuery('/organizations/1/atwho_projects.json',
                             $prevButton,
                             $button);
            break;
          case 'exp':
            generateNewQuery('/organizations/1/atwho_experiments.json',
                             $prevButton,
                             $button);
            break;
          case 'tsk':
            generateNewQuery('/organizations/1/atwho_my_modules.json',
                             $prevButton,
                             $button);
            break;
          case 'sam':
            generateNewQuery('/organizations/1/atwho_samples.json',
                             $prevButton,
                             $button);
            break;
        }
      });
    }

    // Generates new query when user filters the results
    function generateNewQuery(link, prevBtn, selectedBtn) {
      var regexp, _a, _y, new_query, query_obj;
      _a = decodeURI("%C3%80");
      _y = decodeURI("%C3%BF");
      regexp = new RegExp("(#|task#|project#|sample#|experiment#)([A-Za-z" +
      _a + "-" + _y + "0-9_ \'\.\+\-]*)$|" +
      "(#|task#|project#|sample#|experiment#)([^\\x00-\\xff]*)$", 'gi');
      query_obj = regexp.exec($(field).val());
      new_query = query_obj.input.replace(query_obj[0], '');

      $.getJSON(
        link,
        {query: new_query},
        function(data) {
          if(data.res.length > 0) {
            $(field)
              .atwho('load', query_obj[0], data.res)
              .atwho('run');

            prevBtn
              .removeClass('btn-primary')
              .addClass('btn-default');
            selectedBtn
              .removeClass('btn-default')
              .addClass('btn-primary');

            reinitializeOnListHide();
            initButtons(new_query, query_obj[0]);
          } else {
            $(field).atwho('destroy');
            init();
          }
      });
    }

    // Generates suggestion dropdown filter
    function generateFilterMenu(active, res_data) {
      var header = '<div class="atwho-header">' +
       '<button data-filter="prj" class="btn btn-sm ' +
       (active === 'prj' ? 'btn-primary' : 'btn-default') + '">project #</button>' +
       '<button data-filter="exp" class="btn btn-sm ' +
       (active === 'exp' ? 'btn-primary' : 'btn-default') + '">experiment #</button>' +
       '<button data-filter="tsk" class="btn btn-sm ' +
       (active === 'tsk' ? 'btn-primary' : 'btn-default') + '">task #</button>' +
       '<button data-filter="sam" class="btn btn-sm ' +
       (active === 'sam' ? 'btn-primary' : 'btn-default') + '">sample #</button>' +
       '<div class="help">' +
       '<div>' +
       '<strong><%= I18n.t("atwho.users.navigate_1") %></strong> ' +
       '<%= I18n.t("atwho.users.navigate_2") %>' +
       '</div>' +
       '<div><strong><%= I18n.t("atwho.users.confirm_1") %></strong> ' +
       '<%= I18n.t("atwho.users.confirm_2") %>' +
       '</div>' +
       '<div>' +
       '<strong><%= I18n.t("atwho.users.dismiss_1") %></strong> ' +
       '<%= I18n.t("atwho.users.dismiss_2") %>' +
       '</div>' +
       '<div class="dismiss">' +
       '<span class="glyphicon glyphicon-remove"></span>' +
       '</div>' +
       '</div>' +
       '</div>';

      return header;
    }

    // Generates resources list items
    function generateTemplate(map) {
      var res = '';
      res += '<li class="atwho-li atwho-li-res" data-name="' +
              map.name + '" data-id="' + map.id + '" data-type="' +
              map.type + '">';
      switch(map.type) {
          case 'tsk':
              res += '<span data-type class="res-type">' + map.type + '</span>';
              break;
          case 'prj':
              res += '<span data-type class="res-type">' + map.type + '</span>';
              break;
          case 'exp':
              res += '<span data-type class="res-type">' + map.type + '</span>';
              break;
          case 'sam':
              res += '<span class="glyphicon glyphicon-tint"></span>';
              break;
      }

      res += '&nbsp;';
      res += '<span data-val="name">';
      res += map.name;
      res += '</span>';
      res += '&nbsp;';

      switch (map.type) {
        case 'tsk':
          res += '<span>&lt; ' + map.experimentName +
                 ' &lt; ' + map.projectName + '</span>';
          break;
        case 'exp':
          res += '<span>&lt; ' + map.projectName + '</span>';
          break;
        case 'sam':
          res += '<span>' + map.description + '</span>';
          break;
        default:
          break;
      }

      res += '</li>';
      return res;
    }

    function init() {
      $(field)
      .atwho({
        at: '#',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(
              '/organizations/1/atwho_samples.json',
              {query: query},
              function(data) {
                callback(data.res);
                initButtons(query);
              }
            );
          },
          tplEval: function(_tpl, map) {
            return _templateEval(_tpl, map);
          },
          highlighter:  function(li, query) {
            return _matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return _genrateInputTag(value, li);
          }
        },
        headerTpl: generateFilterMenu('sam'),
        limit: 5,
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      })
      .atwho({
        at: 'task#',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(
              '/organizations/1/atwho_my_modules.json',
              {query: query},
              function(data) {
                callback(data.res);
                initButtons(query, 'task#');
              }
            );
          },
          tplEval: function(_tpl, map) {
            return _templateEval(_tpl, map);
          },
          highlighter: function(li, query) {
            return _matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return _genrateInputTag(value, li);
          }
        },
        headerTpl: generateFilterMenu('tsk'),
        limit: 5,
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      })
      .atwho({
        at: 'project#',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(
              '/organizations/1/atwho_projects.json',
              {query: query},
              function(data) {
                callback(data.res);
                initButtons(query, 'project#');
              }
            );
          },
          tplEval: function(_tpl, map) {
            return _templateEval(_tpl, map);
          },
          highlighter: function(li, query) {
            return _matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return _genrateInputTag(value, li);
          }
        },
        headerTpl: generateFilterMenu('prj'),
        limit: 5,
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      })
      .atwho({
        at: 'experiment#',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(
              '/organizations/1/atwho_experiments.json',
              {query: query},
              function(data) {
                callback(data.res);
                initButtons(query, 'experiment#');
              }
            );
          },
          tplEval: function(_tpl, map) {
            return _templateEval(_tpl, map);
          },
          highlighter: function(li, query) {
            return _matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return _genrateInputTag(value, li);
          }
        },
        headerTpl: generateFilterMenu('exp'),
        limit: 5,
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      })
      .atwho({
        at: 'sample#',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(
              '/organizations/1/atwho_samples.json',
              {query: query},
              function(data) {
                callback(data.res);
                initButtons(query);
              }
            );
          },
          tplEval: function(_tpl, map) {
            return _templateEval(_tpl, map);
          },
          highlighter: function(li, query) {
            return _matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return _genrateInputTag(value, li);
          }
        },
        headerTpl: generateFilterMenu('sam'),
        limit: 5,
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      });
    }

    return {
      init: init
    };
  }

  var smartA = new smartAnnotation('#comment_message');

  $(document).ready(function() {
    setTimeout(function(){
      smartA.init();
    }, 2000);
  });


})();

(function() {
  'use strict';

  function smartAnnotation(field) {

    // Generates new query when user filters the results
    function generateNewQuery(link) {

      var regexp = new XRegExp('(\\s+|^)task#|project#|sample#|experiment#(\\p{L}+)$', 'gi');
      var new_query = regexp.exec($(field).val());
      debugger;
      $.getJSON(
        link,
        {query: new_query},
        function(data) {
        $(field).atwho('load',':', data).atwho('run');
      });
    }

    // Generates suggestion dropdown filter
    function generateFilter(link) {
      $('.atwho-view ul').prepend('<li id="atwho-filter">' +
        '<button data-filter="prj" class="btn btn-sm btn-default">project #</button>' +
        '<button data-filter="exp" class="btn btn-sm btn-default">experiment #</button>' +
        '<button data-filter="tsk" class="btn btn-sm btn-default">task #</button>' +
        '<button data-filter="sam" class="btn btn-sm btn-default">#</button></li>');

      $('#atwho-filter .btn').on('click', function(event) {
        event.stopPropagation();
        var $button = $(this);
        switch ($button.attr('data-filter')) {
          case 'prj':
            generateNewQuery('/organizations/1/atwho_projects.json');
            break;
          case 'exp':
            generateNewQuery('/organizations/1/atwho_experiments.json');
            break;
          case 'tsk':
            generateNewQuery('/organizations/1/atwho_my_modules.json');
            break;
          case 'sam':
            generateNewQuery('/organizations/1/atwho_samples.json');
            break;
          default:
            break;
        }
      });

    }

    // Generates resources list items
    function generateTemplate(map) {
      var res = '';
      res += '<li class="atwho-li atwho-li-res" data-path="' +
              map.path + '" data-id="' + map.id + '">';
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
      res += '<span data-name class="res-name">';
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
      if (_.isUndefined($(field).data('atwho'))) {
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
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = generateTemplate(map);
              } catch (_error) {
                res = '';
              }
              return res;
            },
            beforeReposition: function(offset) {
              generateFilter('bleble');
            }
          },
          displayTpl: '<span>${type}<span><a href="${path}">${name}</a>',
          insertTpl: '[${atwho-at}${name}~${id}]',
          limit: 5,
          startWithSpace: true
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
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = generateTemplate(map);
              } catch (_error) {
                res = '';
              }
              return res;
            },
            beforeReposition: function(offset) {
              generateFilter('bleble');
            }
          },
          displayTpl: '<span>${type}<span><a href="${path}">${name}</a>',
          insertTpl: '[${atwho-at}${name}~${id}]',
          limit: 5,
          startWithSpace: true
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
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = generateTemplate(map);
              } catch (_error) {
                res = '';
              }
              return res;
            },
            beforeReposition: function(offset) {
              generateFilter('bleble');
            }

          },
          displayTpl: '<span>${type}<span><a href="${path}">${name}</a>',
          insertTpl: '[${atwho-at}${name}~${id}]',
          limit: 5,
          startWithSpace: true
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
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = generateTemplate(map);
              } catch (_error) {
                res = '';
              }
              return res;
            },
            beforeReposition: function(offset) {
              generateFilter('bleble');
            }
          },
          displayTpl: '<span>${type}<span><a href="${path}">${name}</a>',
          insertTpl: '[${atwho-at}${name}~${id}]',
          limit: 5,
          startWithSpace: true
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
                }
              );
            },
            tplEval: function(_tpl, map) {
              var res;
              try {
                res = generateTemplate(map);
              } catch (_error) {
                res = '';
              }
              return res;
            },
            beforeReposition: function(offset) {
              generateFilter('bleble');
            }
          },
          displayTpl: '<span class="glyphicon glyphicon-tint"><span>' +
                      '<a href="${path}">${name}</a>',
          insertTpl: '[${atwho-at}${name}~${id}]',
          limit: 5,
          startWithSpace: true
        });
      }
    }
    return { init: init };
  }

  var smartA = new smartAnnotation('#comment_message');

  $(document).ready(function() {
    setTimeout(function(){

      smartA.init();

    }, 1000);
  });


})();

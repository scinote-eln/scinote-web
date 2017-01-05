(function() {
  'use strict';

  function smartAnnotation(field) {

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
                '/organizations/1/atwho_resources.json',
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
                '/organizations/1/atwho_resources.json',
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
                '/organizations/1/atwho_resources.json',
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
                '/organizations/1/atwho_resources.json',
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
                '/organizations/1/atwho_resources.json',
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

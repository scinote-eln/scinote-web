/* global PerfectScrollbar MyModuleRepositories HelperModule _ */

var SmartAnnotation = (function() {
  'use strict';

  // stop the user annotation popover on click propagation
  function atwhoStopPropagation(element) {
    $(element).on('click', function(e) {
      e.stopPropagation();
      e.preventDefault();
    });
  }

  function SetAtWho(field, deferred, assignableMyModuleId) {
    var FilterTypeEnum = Object.freeze({
      USER: { tag: 'users', dataUrl: $(document.body).attr('data-atwho-users-url') },
      TASK: { tag: 'sa-tasks', dataUrl: $(document.body).attr('data-atwho-task-url') },
      PROJECT: { tag: 'sa-projects', dataUrl: $(document.body).attr('data-atwho-project-url') },
      EXPERIMENT: { tag: 'sa-experiments', dataUrl: $(document.body).attr('data-atwho-experiment-url') },
      REPOSITORY: { tag: 'sa-repositories', dataUrl: $(document.body).attr('data-atwho-rep-items-url') },
      MENU: { tag: 'menu', dataUrl: $(document.body).attr('data-atwho-menu-items') }
    });
    var DEFAULT_SEARCH_FILTER = FilterTypeEnum.REPOSITORY;

    function matchHighlighter(html, query) {
      var $html = $(html);
      var $liText = $html.find('.item-text, .sa-type');
      if ($liText.length === 0 || !query) return html;
      const highlightRegex = new RegExp(query.replace(/[()]/g, '\\$&')
        .split(' ')
        .join('|'), 'gi');

      $.each($liText, function(_i, item) {
        $(item).html($(item).text().replace(highlightRegex, '<span class="atwho-highlight">$&</span>'));
      });

      return $html;
    }

    // Generates suggestion dropdown filter
    function generateFilterMenu() {
      var menu = '';
      $.ajax({
        async: false,
        dataType: 'json',
        url: $(document.body).attr('data-atwho-repositories-url'),
        success: function(data) {
          menu = data.html;
        }
      });
      return menu;
    }

    function atWhoSettings(at) {
      return {
        at: at,
        callbacks: {
          remoteFilter: function(query, callback) {

            // show loader after .25 seconds and block other tab clicks
            var loaderTimeout = setTimeout(function() {
              $('.atwho-scroll-container').css({ height: '100px' });
              $('.atwho-scroll-container').html('<div class="loading-overlay" style="padding: 20px"></div>');
              $('.atwho-header-res').css({ 'pointer-events': 'none' });
            }, 250);

            var $currentAtWho = $(`.atwho-view[data-at-who-id=${$(field).attr('data-smart-annotation')}]`);
            var filterType;
            var params = { query: query };
            filterType = FilterTypeEnum[$currentAtWho.find('.tab-pane.active').data('object-type')];
            if (!filterType) {
              clearTimeout(loaderTimeout);
              $('.atwho-header-res').css({ 'pointer-events': '' });

              callback([{ name: '' }]);
              return false;
            }
            if (filterType.tag === 'sa-repositories') {
              let repositoryTab = $currentAtWho.find('[data-object-type="REPOSITORY"]');
              let activeRepository = repositoryTab.find('.btn-primary');
              params.assignable_my_module_id = assignableMyModuleId;
              if (activeRepository.length) {
                params.repository_id = activeRepository.data('object-id');
              }
            }
            $.getJSON(filterType.dataUrl, params, function(data) {
              clearTimeout(loaderTimeout);
              $('.atwho-header-res').css({ 'pointer-events': '' });

              localStorage.setItem('smart_annotation_states/teams/' + data.team, JSON.stringify({
                tag: filterType.tag,
                repository: data.repository
              }));

              callback(data.res);

              if (data.repository) {
                $currentAtWho.find(`.repository-object[data-object-id="${data.repository}"]`)
                  .addClass('btn-primary').removeClass('btn-light');
              }
              if ($('.atwho-scroll-container').last()[0]) {
                // eslint-disable-next-line no-new
                new PerfectScrollbar($('.atwho-scroll-container').last()[0]);
              }
            });
            return true;
          },
          tplEval: function(_tpl, items) {
            var $items = $(items.name);
            $items.find('li').data('item-data', { 'atwho-at': at }); // Emulate at.js insertContentFor method
            return $items;
          },
          highlighter: function(li, query) {
            return matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return `[#${li.attr('data-name')}~${li.attr('data-type')}~${li.attr('data-id')}]`;
          },
          matcher: function(flag, subtext, shouldStartWithSpace) {
            var a;
            var y;
            var match;
            var regexp;
            var cleanedFlag = flag.replace(/[-[]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
            if (shouldStartWithSpace) {
              cleanedFlag = '(?:^|\\s)' + cleanedFlag;
            }
            a = decodeURI('%C3%80');
            y = decodeURI('%C3%BF');
            regexp = new RegExp(`${cleanedFlag}$|` +
                                `${cleanedFlag}(\\S[A-Za-z${a}-${y}0-9_/:\\s\\)\\(.+-]*)$|` +
                                `${cleanedFlag}(\\S[^\\x00-\\xff]*)$`, 'gi');
            match = regexp.exec(subtext);
            if (match) {
              return (match[1] || '').trim();
            }
            return null;
          }
        },
        headerTpl: generateFilterMenu(),
        startWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      };
    }

    function initAtwho() {
      if ($(this).data('atwho-initialized')) return;

      $(field).on('shown.atwho', function() {
        var $currentAtWho = $('.atwho-view[style]:not(.old)');
        var atWhoId = $currentAtWho.find('.atwho-header-res').data('at-who-key');
        $currentAtWho.addClass('old').attr('data-at-who-id', atWhoId);
        $(field).attr('data-smart-annotation', atWhoId);

        $currentAtWho.find('.tab-button').off().on('shown.bs.tab', function() {
          $(field).click().focus();
          $(this).closest('.nav-tabs').find('.tab-button').removeClass('active');
          $(this).addClass('active');
        });
        $currentAtWho.find('.repository-object').off().on('click', function() {
          $(this).parent().find('.repository-object').removeClass('btn-primary')
            .addClass('btn-light');
          $(this).addClass('btn-primary').removeClass('btn-light');
          $(field).click().focus();
        });
        $currentAtWho.on('click', '.atwho-assign-button', function() {
          let el = $(this);
          $.ajax({
            method: 'POST',
            url: el.data('assign-url'),
            data: { repository_row_id: el.data('repository-row-id') },
            dataType: 'json',
            success: function(data) {
              if (typeof MyModuleRepositories !== 'undefined') {
                MyModuleRepositories.reloadRepositoriesList(el.data('repository-id'));
              }
              HelperModule.flashAlertMsg(data.flash, 'success');
            },
            error: function(response) {
              HelperModule.flashAlertMsg(response.responseJSON.flash, 'danger');
            }
          });
        });

        if ($currentAtWho.find('.tab-pane.active').length === 0) {
          let filterType = DEFAULT_SEARCH_FILTER.tag;
          let teamId = $currentAtWho.find('.atwho-header-res').data('team-id');
          let remeberedState = localStorage.getItem('smart_annotation_states/teams/' + teamId);
          if (remeberedState) {
            try {
              remeberedState = JSON.parse(remeberedState);
              filterType = remeberedState.tag;
              $currentAtWho.find(`.repository-object[data-object-id=${remeberedState.repository}]`)
                .addClass('btn-primary');
            } catch (error) {
              console.error(error);
            }
          }
          $currentAtWho.find(`.${filterType}`).click();
        }
      }).on('reposition.atwho', function(event, flag, query) {
        let inputFieldLeft = query.$inputor.offset().left;
        if (inputFieldLeft > $(window).width()) {
          let leftPosition;
          if (inputFieldLeft < flag.left + $(window).scrollLeft()) {
            leftPosition = inputFieldLeft;
          } else {
            leftPosition = flag.left + $(window).scrollLeft();
          }
          query.$el.find('.atwho-view').css('left', leftPosition + 'px');
        }
        if ($('.repository-show').length) {
          query.$el.find('.atwho-view').css('top', flag.top + 'px');
        }
      }).atwho({
        at: '@',
        callbacks: {
          remoteFilter: function(query, callback) {
            $.getJSON(FilterTypeEnum.USER.dataUrl, { query: query }, function(data) {
              callback(data.users);
            });
          },
          tplEval: function(_tpl, items) {
            var $items = $(items.name);
            $items.find('li').data('item-data', { 'atwho-at': '@' }); // Emulate at.js insertContentFor method
            return $items;
          },
          highlighter: function(li, query) {
            return matchHighlighter(li, query);
          },
          beforeInsert: function(value, li) {
            return `[@${li.attr('data-full-name')}~${li.attr('data-id')}]`;
          }
        },
        startsWithSpace: true,
        acceptSpaceBar: true,
        displayTimeout: 120000
      })
        .atwho(atWhoSettings('#'));

      $(this).data('atwho-initialized', true);
    }

    function init() {
      if (deferred) {
        $(field).on('focus', initAtwho);
      } else {
        initAtwho();
      }
    }

    return {
      init: init
    };
  }
  // Closes the atwho popup * needed in repositories to close the popup
  // if nothing is selected and the user leaves the form *
  function closePopup() {
    $('.atwho-header-res').find('.sn-icon-close').click();
  }

  function initialize(field, deferred, assignableMyModuleId) {
    var atWho = new SetAtWho(field, deferred, assignableMyModuleId);
    atWho.init();
  }

  return Object.freeze({
    init: initialize,
    preventPropagation: atwhoStopPropagation,
    closePopup: closePopup
  });
}());


// initialize the smart annotations
(function() {
  $(document).on('focus', '[data-atwho-edit]', function() {
    if (_.isUndefined($(this).data('atwho'))) {
      SmartAnnotation.init(this, false);
    }
  });

  $(document).on('click', '.atwho-view .dismiss', function() {
    $(this).closest('.atwho-view').hide();
  });
}());

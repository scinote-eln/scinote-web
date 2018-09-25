function setupAssetsLoading() {
  var DELAY = 2500;
  var REPETITIONS = 60;

  function refreshAssets() {
    var elements = $("[data-status='asset-loading']");

    if (!elements.length) {
      return false;
    }

    $.each(elements, function(_, el) {
      var $el = $(el);

      // Perform an AJAX call to present URL
      // to check if file already exists
      $.ajax({
        url: $el.data("present-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
          var wopiBtns;
          $el.attr("data-status", "asset-loaded");
          $el.find('img').hide();
          $el.next().hide();
          $el.html("");

          if (data.type === 'image') {
            $el.html(
              "<a class='file-preview-link' id='modal_link" +
              data['asset-id'] + "' data-status='asset-present' " +
              "href='" + data['download-url'] + "' data-preview-url='" +
              data['preview-url'] + "'>" +
              "<img src='" + data['image-tag-url'] + "'><p>" +
              data.filename + '</p></a>'
            );
          } else {
            $el.html(
              "<a class='file-preview-link' id='modal_link" +
              data['asset-id'] + "' data-status='asset-present' " +
              "href='" + data['download-url'] + "' data-preview-url='" +
              data['preview-url'] + "'><p>" +
              data.filename + '</p></a>'
            );
          }
          animateSpinner(null, false);
          initPreviewModal();
        },
        error: function(data) {
          if (data.status == 403) {
            $el.find('img').hide();
            $el.next().hide();
            // Image/file exists, but user doesn't have
            // rights to download it
            if (type === "image") {
              $el.html(
                "<img src='" + data['image-tag-url'] + "'><p>" +
                data.filename + "</p>"
              );
            } else {
              $el.html("<p>" + data.filename + "</p>");
            }
          } else {
            // Do nothing, file is not yet present
            animateSpinner(null, false);
          }
        }
      });
    });

    return true;
  }

  function finalizeAssets() {
    var elements = $("[data-status='asset-loading']");

    $.each(elements, function(_, el) {
      var $el = $(el);
      $el.attr("data-status", "asset-failed");
      $el.html($el.data("filename"));
    });
  }

  var cntr = 0;
  var intervalId = window.setInterval(function() {
    cntr++;
    if (cntr >= REPETITIONS || !refreshAssets()) {
      finalizeAssets();
      window.clearInterval(intervalId);
    }
  }, DELAY);
}
;
var Comments = (function() {
  'use strict';

  /**
    * Initializes the comments
    *
    */
  function initializeComments(){
    var comments;
    if ( $('.step-comment') && $('.step-comment').length > 0 ) {
      comments = $('.step-comment');
    } else if ( $('.result-comment') && $('.result-comment').length > 0 ) {
      comments = $('.result-comment');
    }
    if(!_.isUndefined(comments)) {
      $.each(comments, function(){
        var that = $(this);
        var link = that.attr('data-href');
        $.ajax({ method: 'GET',
                 url: link,
                 beforeSend: animateSpinner(that, true) })
          .done(function(data) {
            that.html(data.html);
            initCommentForm(that);
            initCommentsLink(that);
            scrollBottom(that.find('.content-comments'));
          })
          .always(function() {
            animateSpinner(that, false);
          });
      });
    }
  }

  // scroll to the botttom
  function scrollBottom(id) {
    var list;
    if ( id.hasClass('content-comments') ) {
      list = id;
    } else {
      list = id.find('.content-comments');
    }
    if ( list && list.length > 0) {
      list.scrollTop($(list)[0].scrollHeight);
    }
  }

  // Initialize show more comments link.
  function initCommentsLink($el) {

    $el.find('.btn-more-comments')
    .on('ajax:success', function (e, data) {
      if (data.html) {
        var list = $(this).parents('ul');
        var moreBtn = list.find('.btn-more-comments');
        var listItem = moreBtn.parents('li');

        $(data.html).insertAfter(listItem);
        if (data.resultsNumber < data.perPage) {
          moreBtn.remove();
        } else {
          moreBtn.attr('href', data.moreUrl);
          moreBtn.trigger('blur');
        }

        var date;
        $.each(list.find('.comment-date-separator'), function() {
          if ( $(this).find('p').html() === date ) {
            $(this).remove();
          } else {
            date = $(this).find('p').html();
          }
        });

        // Reposition dropdown comment options
        scrollCommentOptions(listItem
                              .closest('.content-comments')
                              .find('.dropdown-comment'));
      } else {
        $('.btn-more-comments').remove();
      }
    });
  }

  // Initialize comment form.
  function initCommentForm($el) {

    var $form = $el.find('ul form');

    $('.help-block', $form).addClass('hide');

    $form.on('ajax:send', function () {
      $('#comment_message', $form).attr('readonly', true);
    })
    .on('ajax:success', function (e, data) {
      if (data.html) {
        var list = $form.parents('ul');

        // Remove potential 'no comments' element
        list.parent().find('.content-comments')
          .find('li.no-comments').remove();

        // Find previous date separator
        var dateSeparator =  list.parent().find('.comment-date-separator:last');
        if (dateSeparator.length > 0) {
          // Parse string with creation date
          var pr = dateSeparator.text().split('.');
          var comm = data.date.split('.');
          // Build Date objects and compare
          var sepDate = new Date(pr[2], pr[1] - 1, pr[0]);
          var commDate = new Date(comm[2], comm[1] - 1, comm[0]);
          if (commDate > sepDate) {
            // Add date separator
            list.parent().find('.content-comments')
              .append('<li class="comment-date-separator">\
                        <p class="text-center">' + data.date + '</p>\
                      </li>');
          }
        } else {
          // Comment is the first one so add date separator
          list.parent().find('.content-comments')
            .append('<li class="comment-date-separator">\
                      <p class="text-center">' + data.date + '</p>\
                    </li>');
        }

        CounterBadge.updateCounterBadge(data.counter,
                                        data.linked_id, 'comments');

        list.parent().find('.content-comments')
          .append('<li class="comment">' + data.html + '</li>')
          .scrollTop(0);
        list.parents('ul').find('> li.comment:gt(8)').remove();
        $('#comment_message', $form).val('');
        $('.form-group', $form)
          .removeClass('has-error');
        $('.help-block', $form)
            .html('')
            .addClass('hide');
        scrollBottom($el);
      }
    })
    .on('ajax:error', function (ev, xhr) {
      if (xhr.status === 400) {
        var messageError = xhr.responseJSON.errors.message;

        if (messageError) {
          $('.form-group', $form)
            .addClass('has-error');
          $('.help-block', $form)
              .html(messageError[0])
              .removeClass('hide');
        }
      }
    })
    .on('ajax:complete', function () {
      scrollBottom($('#comment_message', $form));
      $('#comment_message', $form)
        .attr('readonly', false)
        .focus();
    });
  }

  // restore comments after update or when new element is created
  function bindCommentInitializerToNewElement() {
    $(document)
      .ready(function() {
        if( document.getElementById('steps') !== null ) {
          $('#steps')
            .change(function() {
              $('.step-save')
                .on('click', function() {
                  $(document)
                    .on('ajax:success', function(){
                      initializeComments();
                    });
                });
            });
        } else if ( document.getElementById('results') !== null ) {
          $('#results')
            .change(function() {
              $('.save-result')
                .on('click', function() {
                  $(document)
                    .on('ajax:success', function(){
                      initializeComments();
                    });
                });
            });
          }
    });
  }

  function initCommentOptions(scrollableContainer, useParentOffset) {
    if ( ! _.isUndefined(useParentOffset) ) {
      useParentOffset = useParentOffset;
    } else {
      useParentOffset = true;
    }
    scrollCommentOptions($('.dropdown-comment'), useParentOffset);

    // Reposition dropdown to the left
    // (only do this when using parent offset)
    if (useParentOffset) {
      $(document).on('shown.bs.dropdown', '.dropdown-comment', function() {
        var $el = $(this);
        var menu = $el.find('.dropdown-menu');
        var leftPos = $el.offset().left;
        var parentTopPos = $el.offset().top;
        if (leftPos + menu.width() > $(window).width()) {
          menu.offset({ left: leftPos - menu.width(),
                        top: (parentTopPos +
                              20)});
        }
      });
    }

    // Reposition dropdowns vertically on scroll events
    document.addEventListener('scroll', function (event) {
      var $target = $(event.target);
      var parent = $(scrollableContainer);

      if ($target.length) {
        scrollCommentOptions(parent.find('.dropdown-comment'), useParentOffset);
      }
    }, true);
  }

  function scrollCommentOptions(selector, useParentOffset) {
    if ( ! _.isUndefined(useParentOffset) ) {
      useParentOffset = useParentOffset;
    } else {
      useParentOffset = true;
    }
    _.each(selector, function(el) {
      var $el = $(el);
      var offset = useParentOffset ? $el.offset().top : $el.position().top;
      $el.find('.dropdown-menu-fixed')
        .offset({ top: (offset + 20) });
    });
  }

  function initDeleteComments(parent) {
    $(parent).on('click', '[data-action=delete-comment]', function() {
      var $this = $(this);
      if (confirm($this.attr('data-confirm-message'))) {
        $.ajax({
          url: $this.attr('data-url'),
          type: 'DELETE',
          dataType: 'json',
          success: function(data) {
            // There are 3 possible actions:
            // - (A) comment is the last comment in project
            // - (B) comment is the last comment inside specific date
            //   (remove the date separator)
            // - (C) comment is a usual comment

            var commentEl = $this.closest('.comment');

            // Case A
            if (commentEl.prevAll('.comment').length === 0 &&
                  commentEl.next().length === 0) {
              commentEl.after('<li class="no-comments"><em>' +
                I18n.t('projects.index.no_comments') + '</em></li>');
            }

            // Case B
            if (commentEl.prev('.comment-date-separator').length > 0 &&
                  commentEl.next('.comment').length === 0) {
              commentEl.prev('.comment-date-separator').remove();
            }
            commentEl.remove();

            CounterBadge.updateCounterBadge(data.counter,
                                            data.linked_id,
                                            'comments');
            scrollCommentOptions($(parent).find('.dropdown-comment'));
          },
          error: function(data) {
            // Display alert
            alert(data.responseJSON.message);
          }
        });
      }
    });
  }

  function initEditComments(parent) {
    $(parent).unbind('click').on('click', '[data-action=edit-comment]', function() {

      var $this = $(this);
      // close dropdown on click
      var dropdown = $($this.parents(".dropdown-comment.open").get(0));
      if(dropdown.length) { // safety first
        dropdown.removeClass('open');
      }
      $.ajax({
          url: $this.attr('data-url'),
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            var commentEl = $this.closest('.comment');
            var container = commentEl
                              .find('[data-role=comment-message-container]');
            var oldMessage = container.find('[data-role=comment-message]');
            var optionsBtn = commentEl.find('[data-role=comment-options]');

            // Hide old message, append new HTML
            oldMessage.hide();
            optionsBtn.hide();
            container.append(data.html);

            var form = container.find('[data-role=edit-comment-message-form]');
            var input = form.find('[data-role=message-input]');
            var submitBtn = form.find('[data-action=save]');
            var cancelBtn = form.find('[data-action=cancel]');

            input.focus();

            form
            .on('ajax:send', function() {
              input.attr('readonly', true);
            })
            .on('ajax:success', function(ev, data) {
              var newMessage = input.val();
              if (!_.isUndefined(data.comment)) {
                newMessage = data.comment;
              }
              oldMessage.html(newMessage);

              form.off('ajax:send ajax:success ajax:error ajax:complete');
              submitBtn.off('click');
              cancelBtn.off('click');
              form.remove();
              oldMessage.show();
              optionsBtn.show();
            })
            .on('ajax:error', function(ev, xhr) {
              if (xhr.status === 422) {
                var messageError = xhr.responseJSON.errors.message;
                if (messageError) {
                  $('.form-group', form)
                  .addClass('has-error');
                  $('.help-block', form)
                  .html(messageError[0] + ' |')
                  .removeClass('hide');
                }
              }
            })
            .on('ajax:complete', function() {
              input.attr('readonly', false).focus();
            });

            submitBtn.on('click', function() {
              form.submit();
            });

            cancelBtn.on('click', function() {
              form.off('ajax:send ajax:success ajax:error ajax:complete');
              submitBtn.off('click');
              cancelBtn.off('click');
              form.remove();
              oldMessage.show();
              optionsBtn.show();
            });
          },
          error: function() {
            // TODO
          }
        });
    });
  }

  return {
    initialize: initializeComments,
    scrollBottom: scrollBottom,
    moreComments: initCommentsLink,
    form: initCommentForm,
    bindNewElement: bindCommentInitializerToNewElement,
    initCommentOptions: initCommentOptions,
    initDeleteComments: initDeleteComments,
    initEditComments: initEditComments
  };

})();



(function(global) {
  'use strict';

  global.Results = (function() {
    var ResultTypeEnum = Object.freeze({
      FILE: 0,
      TABLE: 1,
      TEXT: 2,
      COMMENT: 3
    });

    function init() {
      initHandsOnTables($(document));
      _expandAllResults();
      applyCollapseLinkCallBack();

      Comments.bindNewElement();
      Comments.initialize();

      Comments.initCommentOptions('ul.content-comments');
      Comments.initEditComments('#results');
      Comments.initDeleteComments('#results');

      $(function () {
        $('#results-collapse-btn').click(function () {
          $('.result .panel-collapse').collapse('hide');
          $(document).find('span.collapse-result-icon').each(function()  {
            $(this).addClass('glyphicon-collapse-down');
            $(this).removeClass('glyphicon-collapse-up');
          });
        });

        $('#results-expand-btn').click(_expandAllResults);
      });

      // This checks if the ctarget param exist in the rendered url and opens the
      // comment tab
      if( getParam('ctarget') ){
        var target = '#'+ getParam('ctarget');
        $(target).find('a.comment-tab-link').click();
      }
    }

    function initHandsOnTables(root) {
      root.find('div.hot-table').each(function()  {
        var $container = $(this).find('.step-result-hot-table');
        var contents = $(this).find('.hot-contents');

        $container.handsontable({
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: true,
          colHeaders: true,
          fillHandle: false,
          formulas: true,
          cells: function (row, col, prop) {
            var cellProperties = {};

            if (col >= 0)
              cellProperties.readOnly = true;
            else
              cellProperties.readOnly = false;

            return cellProperties;
          }
        });
        var hot = $container.handsontable('getInstance');
        var data = JSON.parse(contents.attr('value'));
        hot.loadData(data.data);
      });
    }

    function applyCollapseLinkCallBack() {
      $('.result-panel-collapse-link')
        .on('ajax:success', function() {
          var collapseIcon = $(this).find('.collapse-result-icon');
          var collapsed = $(this).hasClass('collapsed');
          // Toggle collapse button
          collapseIcon.toggleClass('glyphicon-collapse-up', !collapsed);
          collapseIcon.toggleClass('glyphicon-collapse-down', collapsed);
        });
    }

    // Toggle editing buttons
    function toggleResultEditButtons(show) {
      if(show) {
        $('#results-toolbar').show();
        $('.edit-result-button').show();
      } else {
        $('.edit-result-button').hide();
        $('#results-toolbar').hide();
      }
    }

    // Expand all results
    function _expandAllResults() {
      $('.result .panel-collapse').collapse('show');
      $(document).find('span.collapse-result-icon').each(function()  {
        $(this).addClass('glyphicon-collapse-up');
        $(this).removeClass('glyphicon-collapse-down');
      });
      $(document).find('div.step-result-hot-table').each(function()  {
        _renderTable(this);
      });
    }

    function expandResult(result) {
      $('.panel-collapse', result).collapse('show');
      $(result).find('span.collapse-result-icon').each(function()  {
        $(this).addClass('glyphicon-collapse-up');
        $(this).removeClass('glyphicon-collapse-down');
      });
      _renderTable($(result).find('div.step-result-hot-table'));
      animateSpinner(null, false);
      setupAssetsLoading();
    }

    function _renderTable(table) {
      $(table).handsontable('render');
      // Yet another dirty hack to solve HandsOnTable problems
      if (parseInt($(table).css('height'), 10) <
            parseInt($(table).css('max-height'), 10) - 30) {
        $(table).find('.ht_master .wtHolder').css({ 'height': '100%',
                                                     'width': '100%' });
      }
    }

    function processResult(ev, resultTypeEnum, editMode) {
      var $form = $(ev.target.form);
      $form.clearFormErrors();

      switch(resultTypeEnum) {
        case ResultTypeEnum.FILE:
          _handleResultFileSubmit($form, ev);
          break;
        case ResultTypeEnum.TABLE:
          var $nameInput = $form.find('#result_name');
          var nameValid = textValidator(ev, $nameInput, 0,
            255);
          break;
        case ResultTypeEnum.TEXT:
          var $nameInput = $form.find('#result_name');
          var nameValid = textValidator(ev, $nameInput, 0,
            255);
          var $descrTextarea = $form.find("#result_result_text_attributes_text");
          var $tinyMCEInput = TinyMCE.getContent();
          textValidator(ev, $descrTextarea, 1, 10000, false, $tinyMCEInput);
          break;
        case ResultTypeEnum.COMMENT:
          var $commentInput = $form.find('#comment_message');
          var commentValid = textValidator(ev, $commentInput, 1,
            10000);
          break;
      }
    }

    // create custom ajax request in order to fix issuses with remote: true from
    function _handleResultFileSubmit(form, ev) {
      ev.preventDefault();
      ev.stopPropagation();
      animateSpinner();
      var data = new FormData();
      var file = document.getElementById('result_asset_attributes_file')
                         .files[0];
      data.append('result[name]', form.find('#result_name').val());
      data.append('result[asset_attributes][id]',
                  form.find('#result_asset_attributes_id').val());
      if( file ) {
        data.append('result[asset_attributes][file]', file);
      }

      $.ajax({
        type: 'PUT',
        url: form.attr('action'),
        data: data,
        success: function(data) {
          animateSpinner(null, false);
          $('.edit_result').parent().remove();
          $(data.html).prependTo('#results').promise().done(function() {
            $.each($('#results').find('.result'),
                   function() {
              initFormSubmitLinks($(this));
              ResutlAssets.applyEditResultAssetCallback();
              applyCollapseLinkCallBack();
              toggleResultEditButtons(true);
              initPreviewModal();
              Comments.initialize();
              ResutlAssets.initNewResultAsset();
              expandResult($(this));
            });

          });
          $('#results-toolbar').show();
        },
        error: function(XHR) {
          animateSpinner(null, false)
          $('.edit_result').renderFormErrors('result',
                                             XHR.responseJSON['errors']);

        },
        processData: false,
        contentType: false,
      });
    }

    // init cancel button
    function initCancelFormButton(form, callback) {
      $(form).find('.cancel-new').click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        $(form).remove();
        toggleResultEditButtons(true);
        callback();
      });
    }

    function archive(e, element) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      var el = $(element);
      if(confirm(el.data('confirm-text'))) {
        animateSpinner();
        $('#' + el.data('form-id')).submit();
      }
    }

    var publicAPI = Object.freeze({
      init: init,
      initHandsOnTables: initHandsOnTables,
      applyCollapseLinkCallBack: applyCollapseLinkCallBack,
      toggleResultEditButtons: toggleResultEditButtons,
      expandResult: expandResult,
      processResult: processResult,
      ResultTypeEnum: ResultTypeEnum,
      initCancelFormButton: initCancelFormButton,
      archive: archive
    });

    return publicAPI;
  })();

  $(document).ready(function(){
    Results.init();
  });
})(window);

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
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// TODO
// - error handling of assigning user to project, check XHR data.errors
// - error handling of removing user from project, check XHR data.errors
// - refresh project users tab after manage user modal is closed
// - refactor view handling using library, ex. backbone.js


(function () {

  var newProjectModal = null;
  var newProjectModalForm = null;
  var newProjectModalBody = null;
  var newProjectBtn = null;

  var editProjectModal = null;
  var editProjectModalTitle = null;
  var editProjectModalBody = null;
  var editProjectBtn = null;

  var projectActionsModal = null;
  var projectActionsModalHeader = null;
  var projectActionsModalBody = null;
  var projectActionsModalFooter = null;

  /**
   * Stupid Bootstrap btn-group bug hotfix
   * @param btnGroup - The button group element.
   */
  function activateBtnGroup(btnGroup) {
    var btns = btnGroup.find(".btn");
    btns.find("input[type='radio']")
    .removeAttr("checked")
    .prop("checked", false);
    btns.filter(".active")
    .find("input[type='radio']")
    .attr("checked", "checked")
    .prop("checked", true);
  }

  /**
   * Initializes page
   */
  function init() {
    newProjectModal = $('#new-project-modal');
    newProjectModalForm = newProjectModal.find('form');
    newProjectModalBody = newProjectModal.find('.modal-body');
    newProjectBtn = $('#new-project-btn');

    editProjectModal = $('#edit-project-modal');
    editProjectModalTitle = editProjectModal.find('#edit-project-modal-label');
    editProjectModalBody = editProjectModal.find('.modal-body');
    editProjectBtn = editProjectModal.find(".btn[data-action='submit']");

    projectActionsModal = $('#project-actions-modal');
    projectActionsModalHeader = projectActionsModal.find('.modal-title');
    projectActionsModalBody = projectActionsModal.find('.modal-body');
    projectActionsModalFooter = projectActionsModal.find('.modal-footer');

    initNewProjectModal();
    initEditProjectModal();
    initManageUsersModal();
    Comments.initCommentOptions('ul.content-comments', true);
    Comments.initEditComments('.panel-project .tab-content');
    Comments.initDeleteComments('.panel-project .tab-content');

    // initialize project tab remote loading
    $('.panel-project .panel-footer [role=tab]')

      .on('ajax:before', function(e) {
        var $this = $(this);
        var parentNode = $this.parents('li');
        var targetId = $this.attr('aria-controls');

        if (parentNode.hasClass('active')) {
          // TODO move to fn
          parentNode.removeClass('active');
          $('#' + targetId).removeClass('active');
          return false;
        }
      })

      .on('ajax:success', function(e, data, status, xhr) {
        var $this = $(this);
        var targetId = $this.attr('aria-controls');
        var target = $('#' + targetId);
        var parentNode = $this.parents('ul').parent();

        target.html(data.html);
        initUsersEditLink(parentNode);
        Comments.form(parentNode);
        Comments.moreComments(parentNode);

        // TODO move to fn
        parentNode.find('.active').removeClass('active');
        $this.parents('li').addClass('active');
        target.addClass('active');

        Comments.scrollBottom(parentNode);
      })

      .on('ajax:error', function() {
        // TODO
      });
  }

  /**
   * Initialize the JS for new project modal to work.
   */
  function initNewProjectModal() {
    newProjectModalForm.submit(function() {
      // Stupid Bootstrap btn-group bug hotfix
      activateBtnGroup(
        newProjectModal
        .find("form .btn-group[data-toggle='buttons']")
      );
    });
    newProjectModal.on("hidden.bs.modal", function () {
      // When closing the new project modal, clear its input vals
      // and potential errors
      newProjectModalForm.clearFormErrors();

      // Clear input fields
      newProjectModalForm.clearFormFields();
      var teamSelect = newProjectModalForm.find('select#project_team_id');
      teamSelect.val(0);
      teamSelect.selectpicker('refresh');

      var teamHidden = newProjectModalForm.find('input#project_visibility_hidden');
      var teamVisible = newProjectModalForm.find('input#project_visibility_visible');
      teamHidden.prop("checked", true);
      teamHidden.attr("checked", "checked");
      teamHidden.parent().addClass("active");
      teamVisible.prop("checked", false);
      teamVisible.parent().removeClass("active");
    })
    .on("show.bs.modal", function() {
      var teamSelect = newProjectModalForm.find('select#project_team_id');
      teamSelect.selectpicker('refresh');
    });

    newProjectModalForm
    .on("ajax:beforeSend", function(){
      animateSpinner(newProjectModalBody);
    })
    .on("ajax:success", function(data, status, jqxhr) {
      // Redirect to response page
      $(location).attr("href", status.url);
    })
    .on("ajax:error", function(jqxhr, status, error) {
      $(this).renderFormErrors("project", status.responseJSON);
    })
    .on("ajax:complete", function(){
      animateSpinner(newProjectModalBody, false);
    });

    newProjectBtn.click(function(e) {
      // Show the modal
      newProjectModal.modal("show");
      return false;
    });
  }

  /**
   * Initialize the JS for edit project modal to work.
   */
  function initEditProjectModal() {
    // Edit button click handler
    editProjectBtn.click(function() {
      // Stupid Bootstrap btn-group bug hotfix
      activateBtnGroup(
        editProjectModalBody
        .find("form .btn-group[data-toggle='buttons']")
      );

      // Submit the modal body's form
      editProjectModalBody.find("form").submit();
    });

    // On hide modal handler
    editProjectModal.on("hidden.bs.modal", function() {
      editProjectModalBody.html("");
    });

    $(".panel-project a[data-action='edit']")
    .on("ajax:success", function(ev, data, status) {
      // Update modal title
      editProjectModalTitle.html(data.title);

      // Set modal body
      editProjectModalBody.html(data.html);

      // Add modal body's submit handler
      editProjectModal.find("form")
      .on("ajax:beforeSend", function(){
        animateSpinner(this);
      })
      .on("ajax:success", function(ev2, data2, status2) {
        // Project saved, replace changed project's title
        var responseHtml = $(data2.html);
        var id = responseHtml.attr("data-id");
        var newTitle = responseHtml.find(".panel-title");
        var existingTitle =
          $(".panel-project[data-id='" + id + "'] .panel-title");

        existingTitle.after(newTitle);
        existingTitle.remove();

        // Hide modal
        editProjectModal.modal("hide");
      })
      .on("ajax:error", function(ev2, data2, status2) {
        $(this).renderFormErrors("project", data2.responseJSON);
      })
      .on("ajax:complete", function(){
        animateSpinner(this, false);
      });

      // Show the modal
      editProjectModal.modal("show");
    })
    .on("ajax:error", function(ev, data, status) {
      // TODO
    });
  }

  function initManageUsersModal() {
    // Reload users tab HTML element when modal is closed
    projectActionsModal.on("hide.bs.modal", function () {
      var projectEl = $("#" + $(this).attr("data-project-id"));

      // Load HTML to refresh users list
      $.ajax({
        url: projectEl.attr("data-project-users-tab-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
          projectEl.find("#users-" + projectEl.attr("id")).html(data.html);
          CounterBadge.updateCounterBadge(data.counter,
                                          data.project_id,
                                          'users');
          initUsersEditLink(projectEl);
        },
        error: function (data) {
          // TODO
        }
      });
    });

    // Remove modal content when modal window is closed.
    projectActionsModal.on("hidden.bs.modal", function () {
      projectActionsModalHeader.html("");
      projectActionsModalBody.html("");
      projectActionsModalFooter.html("");
    });
  }

  // Initialize users editing modal remote loading.
  function initUsersEditLink($el) {

     $el.find(".manage-users-link")

       .on("ajax:before", function () {
        var projectId = $(this).closest(".panel-default").attr("id");
          projectActionsModal.attr("data-project-id", projectId);
          projectActionsModal.modal('show');
       })

       .on("ajax:success", function (e, data) {
         $("#manage-users-modal-project").text(data.project.name);
         initUsersModalBody(data);
       });
  }

  // Initialize reloading manage user modal content after posting new
  // user.

  function initAddUserForm() {

    projectActionsModalBody.find(".add-user-form")

      .on("ajax:success", function (e, data) {
        initUsersModalBody(data);
        if (data.status === 'error') {
          $(this).addClass("has-error");
          var errorBlock = $(this).find("span.help-block");
          if (errorBlock .length && errorBlock.length > 0) {
            errorBlock.html(data.error);
          } else {
            $(this).append("<span class='help-block col-xs-8'>" + data.error + "</span>");
          }
        }
      });
  }

  // Initialize remove user from project links.
  function initRemoveUserLinks() {

    projectActionsModalBody.find(".remove-user-link")

      .on("ajax:success", function (e, data) {
        initUsersModalBody(data);
      });
  }

  //
  function initUserRoleForms() {

    projectActionsModalBody.find(".update-user-form select")

      .on("change", function () {
        $(this).parents("form").submit();
      });

    projectActionsModalBody.find(".update-user-form")

      .on("ajax:success", function (e, data) {
        initUsersModalBody(data);
      })

      .on("ajax:error", function (e, xhr, status, error) {
        // TODO
      });
  }

  // Initialize ajax listeners and elements style on modal body. This
  // function must be called when modal body is changed.
  function initUsersModalBody(data) {
    projectActionsModalHeader.html(data.html_header);
    projectActionsModalBody.html(data.html_body);
    projectActionsModalFooter.html(data.html_footer);
    projectActionsModalBody.find(".selectpicker").selectpicker();
    initAddUserForm();
    initRemoveUserLinks();
    initUserRoleForms();
  }

  init();
}());

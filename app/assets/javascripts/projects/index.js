// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// TODO
// - error handling of assigning user to project, check XHR data.errors
// - error handling of removing user from project, check XHR data.errors
// - refresh project users tab after manage user modal is closed
// - refactor view handling using library, ex. backbone.js

/* global Comments CounterBadge animateSpinner */

//= require comments
(function() {
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

  var projectsViewMode = 'cards';
  var projectsViewFilter = $('.projects-view-filter.active').data('filter');

  function initProjectsViewFilter() {
    $('.projects-view-filter').click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      $('.projects-view-filter').removeClass('active');
      $(this).addClass('active');
      if ($(this).data('filter') === projectsViewFilter) {
        return;
      }
      projectsViewFilter = $(this).data('filter');
    });
  }

  function initProjectsViewModeSwitch() {
    $('input[name=projects-view-mode-selector]').on('change', function() {
      if ($(this).val() === projectsViewMode) {
        return;
      }
      projectsViewMode = $(this).val();
    });
  }

  /**
   * Initialize the JS for new project modal to work.
   */
  function initNewProjectModal() {
    newProjectModal.on('hidden.bs.modal', function() {
      var teamSelect = newProjectModalForm.find('select#project_team_id');
      var teamHidden = newProjectModalForm.find('input#project_visibility_hidden');
      var teamVisible = newProjectModalForm.find('input#project_visibility_visible');
      // When closing the new project modal, clear its input vals
      // and potential errors
      newProjectModalForm.clearFormErrors();

      // Clear input fields
      newProjectModalForm.clearFormFields();
      teamSelect.val(0);
      teamSelect.selectpicker('refresh');

      teamHidden.prop('checked', true);
      teamHidden.attr('checked', 'checked');
      teamHidden.parent().addClass('active');
      teamVisible.prop('checked', false);
      teamVisible.parent().removeClass('active');
    }).on('show.bs.modal', function() {
      var teamSelect = newProjectModalForm.find('select#project_team_id');
      teamSelect.selectpicker('refresh');
    });

    newProjectModalForm
      .on('ajax:beforeSend', function() {
        animateSpinner(newProjectModalBody);
      })
      .on('ajax:success', function(data, status) {
        // Redirect to response page
        $(location).attr('href', status.url);
      })
      .on('ajax:error', function(jqxhr, status) {
        $(this).renderFormErrors('project', status.responseJSON);
      })
      .on('ajax:complete', function() {
        animateSpinner(newProjectModalBody, false);
      });

    newProjectBtn.click(function() {
      // Show the modal
      newProjectModal.modal('show');
      return false;
    });
  }

  /**
   * Initialize the JS for edit project modal to work.
   */
  function initEditProjectModal() {
    // Edit button click handler
    editProjectBtn.click(function() {
      // Submit the modal body's form
      editProjectModalBody.find('form').submit();
    });

    // On hide modal handler
    editProjectModal.on('hidden.bs.modal', function() {
      editProjectModalBody.html('');
    });

    $(".panel-project a[data-action='edit']")
      .on('ajax:success', function(ev, data) {
        // Update modal title
        editProjectModalTitle.html(data.title);

        // Set modal body
        editProjectModalBody.html(data.html);

        // Add modal body's submit handler
        editProjectModal.find('form')
          .on('ajax:beforeSend', function() {
            animateSpinner(this);
          })
          .on('ajax:success', function(ev2, data2) {
            // Project saved, replace changed project's title
            var responseHtml = $(data2.html);
            var id = responseHtml.attr('data-id');
            var newTitle = responseHtml.find('.panel-title');
            var existingTitle = $(".panel-project[data-id='" + id + "'] .panel-title");

            existingTitle.after(newTitle);
            existingTitle.remove();

            // Hide modal
            editProjectModal.modal('hide');
          })
          .on('ajax:error', function(ev2, data2) {
            $(this).renderFormErrors('project', data2.responseJSON);
          })
          .on('ajax:complete', function() {
            animateSpinner(this, false);
          });

        // Show the modal
        editProjectModal.modal('show');
      })
      .on('ajax:error', function() {
        // TODO
      });
  }

  function initManageUsersModal() {
    // Reload users tab HTML element when modal is closed
    projectActionsModal.on('hide.bs.modal', function() {
      var projectEl = $('#' + $(this).attr('data-project-id'));

      // Load HTML to refresh users list
      $.ajax({
        url: projectEl.attr('data-project-users-tab-url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          projectEl.find('#users-' + projectEl.attr('id')).html(data.html);
          CounterBadge.updateCounterBadge(
            data.counter, data.project_id, 'users'
          );
          initUsersEditLink(projectEl);
        },
        error: function() {
          // TODO
        }
      });
    });

    // Remove modal content when modal window is closed.
    projectActionsModal.on('hidden.bs.modal', function() {
      projectActionsModalHeader.html('');
      projectActionsModalBody.html('');
      projectActionsModalFooter.html('');
    });
  }

  // Initialize users editing modal remote loading.
  function initUsersEditLink($el) {
    $el.find('.manage-users-link')
      .on('ajax:before', function() {
        var projectId = $(this).closest('.panel-default').attr('id');
        projectActionsModal.attr('data-project-id', projectId);
        projectActionsModal.modal('show');
      })
      .on('ajax:success', function(e, data) {
        $('#manage-users-modal-project').text(data.project.name);
        initUsersModalBody(data);
      });
  }

  // Initialize reloading manage user modal content after posting new
  // user.

  function initAddUserForm() {
    projectActionsModalBody.find('.add-user-form')
      .on('ajax:success', function(e, data) {
        var errorBlock;
        initUsersModalBody(data);
        if (data.status === 'error') {
          $(this).addClass('has-error');
          errorBlock = $(this).find('span.help-block');
          if (errorBlock.length && errorBlock.length > 0) {
            errorBlock.html(data.error);
          } else {
            $(this).append("<span class='help-block col-xs-8'>" + data.error + '</span>');
          }
        }
      });
  }

  // Initialize remove user from project links.
  function initRemoveUserLinks() {
    projectActionsModalBody.find('.remove-user-link')
      .on('ajax:success', function(e, data) {
        initUsersModalBody(data);
      });
  }

  //
  function initUserRoleForms() {
    projectActionsModalBody.find('.update-user-form select')
      .on('change', function() {
        $(this).parents('form').submit();
      });

    projectActionsModalBody.find('.update-user-form')
      .on('ajax:success', function(e, data) {
        initUsersModalBody(data);
      })
      .on('ajax:error', function() {
        // TODO
      });
  }

  // Initialize ajax listeners and elements style on modal body. This
  // function must be called when modal body is changed.
  function initUsersModalBody(data) {
    projectActionsModalHeader.html(data.html_header);
    projectActionsModalBody.html(data.html_body);
    projectActionsModalFooter.html(data.html_footer);
    projectActionsModalBody.find('.selectpicker').selectpicker();
    initAddUserForm();
    initRemoveUserLinks();
    initUserRoleForms();
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

    initProjectsViewFilter();
    initProjectsViewModeSwitch();
    initNewProjectModal();
    initEditProjectModal();
    initManageUsersModal();
    Comments.initCommentOptions('ul.content-comments', true);
    Comments.initEditComments('.panel-project .tab-content');
    Comments.initDeleteComments('.panel-project .tab-content');

    // initialize project tab remote loading
    $('.panel-project .active').removeClass('active');
    $('.panel-project .panel-footer [role=tab]')
      .on('ajax:before', function() {
        var $this = $(this);
        var parentNode = $this.parents('li');
        var targetId = $this.attr('aria-controls');

        if (parentNode.hasClass('active')) {
          // TODO move to fn
          parentNode.removeClass('active');
          $('#' + targetId).removeClass('active');
          return false;
        }
        return true;
      })
      .on('ajax:success', function(e, data) {
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

  init();
}());

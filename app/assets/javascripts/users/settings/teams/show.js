/* global TinyMCE I18n HelperModule animateSpinner */
(function() {
  'use strict';

  var usersDatatable = null;

  // Initialize edit description modal window
  function initEditDescription() {
    $('.team-description .tinymce-view').off('click').on('click', function() {
      TinyMCE.init(`#${$(this).next().find('textarea').attr('id')}`);
    });
  }

  // Initialize users DataTable
  function initUsersTable() {
    usersDatatable = $('#users-table').DataTable({
      dom: `R
        <'table-header'
          <'add-new-team-members'>
          <'filter-table'f>
          <'display-limit'l>
        >
        <'table-body't>
        <'table-footer'
          <'page-info'i>
          <'page-selector'p>
        >`,
      order: [[0, 'asc']],
      stateSave: true,
      buttons: [],
      processing: true,
      serverSide: true,
      ajax: {
        url: $('#users-table').data('source'),
        type: 'POST'
      },
      colReorder: {
        fixedColumnsLeft: 1000000 // Disable reordering
      },
      columnDefs: [{
        targets: [0, 1, 2, 3, 4],
        searchable: true,
        orderable: true
      }, {
        targets: 5,
        searchable: false,
        orderable: false,
        sWidth: '1%'
      }],
      columns: [
        { data: '0' },
        { data: '1' },
        { data: '2' },
        { data: '3' },
        { data: '4' },
        { data: '5' }
      ],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      }
    });
    $('#add-new-team-members-button').detach().appendTo('.users-datatable .add-new-team-members').removeClass('hidden');
    setTimeout(() => { $('#users-table').css('width', '100%'); }, 300);
  }

  function initUpdateRoles() {
    // Bind on click event of various "set role" links in user
    // dropdowns.
    $('.users-datatable').on('click', "[data-action='submit-role']", function() {
      var link = $(this);
      var form = link
        .closest('.dropdown-menu')
        .find("form[data-id='update-role-form']");
      var hiddenField = form.find("input[data-field='role']");

      // Update the hidden field of the parent form
      hiddenField.attr('value', link.attr('data-value'));

      // Submit the parent form
      form.submit();
    });

    $(document).on(
      'ajax:success',
      "[data-id='update-role-form']",
      function(e, data) {
        // If user does'n have permission to view the team anymore
        // he/she is redirected to teams page
        if (data.new_path) {
          location.replace(data.new_path);
        } else {
          // Reload the whole table
          usersDatatable.ajax.reload();
        }
      }
    ).on(
      'ajax:error',
      "[data-id='update-role-form']",
      function() {
        // TODO
      }
    );
  }

  function initRemoveUsers() {
    // Bind the "remove user" button in users dropdown
    $(document).on(
      'ajax:success',
      "[data-action='destroy-user-team']",
      function(e, data) {
        // Populate the modal heading & body
        var modal = $('#destroy-user-team-modal');
        var modalHeading = modal.find('.modal-header').find('.modal-title');
        var modalBody = modal.find('.modal-body');
        modalHeading.text($('<div>').html(data.heading).text());
        modalBody.html(data.html);

        // Show the modal
        modal.modal('show');
      }
    ).on(
      'ajax:error',
      "[data-action='destroy-user-team']",
      function() {
        // TODO
      }
    );

    // Also, bind the click action on the modal
    $('#destroy-user-team-modal')
      .on('click', "[data-action='submit']", function() {
        var btn = $(this);
        var form = btn
          .closest('.modal')
          .find('.modal-body')
          .find("form[data-id='destroy-user-team-form']");

        // Simply submit the form!
        form.submit();
      });

    // Lastly, bind on the ajax form
    $(document).on(
      'ajax:success',
      "[data-id='destroy-user-team-form']",
      function() {
        // Hide modal & clear its contents
        var modal = $('#destroy-user-team-modal');
        var modalHeading = modal.find('.modal-header').find('.modal-title');
        var modalBody = modal.find('.modal-body');
        modalHeading.text('');
        modalBody.html('');

        // Hide the modal
        modal.modal('hide');

        // Reload the whole table
        usersDatatable.ajax.reload();
      }
    ).on(
      'ajax:error',
      "[data-id='destroy-user-team-form']",
      function() {
        // TODO
      }
    );
  }

  function initReloadPageAfterInviteUsers() {
    $('[data-id=team-invite-users-modal]').on('hidden.bs.modal', function() {
      if (!_.isUndefined($(this).attr('data-invited'))) {
        // Reload page
        location.reload();
      }
    });
  }

  function initNameUpdateEvent() {
    $('.settings-team-name').off('inlineEditing:fieldUpdated', '.inline-editing-container')
      .on('inlineEditing:fieldUpdated', '.inline-editing-container', function() {
        var newName = $(this).find('.view-mode').text();
        $('.breadcrumb-teams .active').text(newName);
        if ($('.settings-team-name').data('current-team')) {
          $('#team-switch .selected-team').text(newName);
        }
      });
  }

  function initTeamSharePermission() {
    function toogleCheckbox() {
      var checkbox = $('.team-share-permission');
      checkbox.prop('checked', !checkbox.prop('checked'));
    }

    $('.team-share-permission').on('click', function(e) {
      animateSpinner();
      e.preventDefault();
      if (this.checked) {
        $.ajax({
          type: 'POST',
          url: $(this).data('enableUrl'),
          success: function() {
            toogleCheckbox();
            animateSpinner(null, false);
            HelperModule.flashAlertMsg(
              I18n.t('users.settings.teams.show.tasks_share.enable_success_message'),
              'success'
            );
          },
          error: function() {
            animateSpinner(null, false);
            HelperModule.flashAlertMsg(I18n.t('users.settings.teams.show.tasks_share.failure_message'), 'danger');
          }
        });
      } else {
        $.ajax({
          type: 'GET',
          url: $(this).data('disableUrl'),
          success: function(data) {
            animateSpinner(null, false);
            if ($('#team-sharing-tasks').length) {
              $('#team-sharing-tasks').replaceWith(data.html);
            } else {
              $('.team-settings-pane').append(data.html);
            }

            $('#team-sharing-tasks').modal('show');
          },
          error: function() {
            animateSpinner(null, false);
            HelperModule.flashAlertMsg(I18n.t('users.settings.teams.show.tasks_share.failure_message'), 'danger');
          }
        });
      }
    });

    $(document)
      .on('ajax:success', '.disable-team-tasks-sharing-form', function() {
        $('#team-sharing-tasks').modal('hide');
        toogleCheckbox();
        HelperModule.flashAlertMsg(I18n.t('users.settings.teams.show.tasks_share.disable_success_message'), 'success');
      })
      .on('ajax:error', '.disable-team-tasks-sharing-form', function() {
        $('#team-sharing-tasks').modal('hide');
        HelperModule.flashAlertMsg(I18n.t('users.settings.teams.show.tasks_share.failure_message'), 'danger');
      });
  }

  initEditDescription();
  initUsersTable();
  initUpdateRoles();
  initRemoveUsers();
  initReloadPageAfterInviteUsers();
  initNameUpdateEvent();
  initTeamSharePermission();
}());

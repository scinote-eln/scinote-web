// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// TODO
// - error handling of assigning user to project, check XHR data.errors
// - error handling of removing user from project, check XHR data.errors
// - refresh project users tab after manage user modal is closed
// - refactor view handling using library, ex. backbone.js

/* global Comments CounterBadge animateSpinner initFormSubmitLinks HelperModule
   I18n setupSidebarTree */

(function(global) {
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

  var exportProjectsModal = null;
  var exportProjectsModalHeader = null;
  var exportProjectsModalBody = null;
  var exportProjectsBtn = null;
  var exportProjectsSubmit = null;

  var projectsViewMode = 'cards';
  var projectsViewFilter = $('.projects-view-filter.active').data('filter');
  var projectsViewFilterChanged = false;
  var projectsChanged = false;
  var projectsViewSort = $('#sortMenuDropdown a.disabled').data('sort');

  var TABLE;

  // Array with selected project IDs shared between both views
  var selectedProjects = [];

  /**
   * Initialize the JS for new project modal to work.
   */
  function initNewProjectModal() {
    newProjectModal.off().on('hidden.bs.modal', function() {
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

    newProjectModalForm.off()
      .on('ajax:beforeSend', function() {
        animateSpinner(newProjectModalBody);
      })
      .on('ajax:success', function(ev, data) {
        projectsChanged = true;
        refreshCurrentView();
        newProjectModal.modal('hide');
        HelperModule.flashAlertMsg(data.message, 'success');
      })
      .on('ajax:error', function(jqxhr, status) {
        $(this).renderFormErrors('project', status.responseJSON);
      })
      .on('ajax:complete', function() {
        animateSpinner(newProjectModalBody, false);
      });

    newProjectBtn.off().click(function() {
      // Show the modal
      newProjectModal.modal('show');

      return false;
    });
  }

  // init project archive/restore function
  function initArchiveRestoreButton(el) {
    el.find('form.edit_project').off()
      .on('ajax:beforeSend', function() {
        animateSpinner($('#projects-cards-view').closest('.tab-content'));
      })
      .on('ajax:success', function(ev, data) {
        projectsChanged = true;
        HelperModule.flashAlertMsg(data.message, 'success');
        // Project saved, reload view
        refreshCurrentView();
      })
      .on('ajax:error', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      })
      .on('ajax:complete', function() {
        animateSpinner($('#projects-cards-view').closest('.tab-content'), false);
      });
  }

  function initEditProjectButton(el) {
    el.find(".dropdown-menu a[data-action='edit']").off()
      .on('ajax:success', function(ev, data) {
        // Update modal title
        editProjectModalTitle.html(data.title);

        // Set modal body
        editProjectModalBody.html(data.html);

        // Add modal body's submit handler
        editProjectModal.find('form').off()
          .on('ajax:beforeSend', function() {
            animateSpinner(this);
          })
          .on('ajax:success', function(ev2, data2) {
            projectsChanged = true;
            // Hide modal
            editProjectModal.modal('hide');

            HelperModule.flashAlertMsg(data2.message, 'success');

            // Project saved, reload view
            refreshCurrentView();
          })
          .on('ajax:error', function(ev2, data2) {
            $(this).renderFormErrors('project', data2.responseJSON.errors);
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

  /**
   * Initialize the JS for edit project modal to work.
   */
  function initEditProjectModal() {
    // Edit button click handler
    editProjectBtn.off().click(function() {
      // Submit the modal body's form
      editProjectModalBody.find('form').submit();
    });

    // On hide modal handler
    editProjectModal.off().on('hidden.bs.modal', function() {
      editProjectModalBody.html('');
    });
  }

  function initManageUsersModal() {
    // Reload users tab HTML element when modal is closed
    projectActionsModal.off('hide.bs.modal').on('hide.bs.modal', function() {
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
          projectsChanged = true;
        },
        error: function() {
          // TODO
        }
      });
    });

    // Remove modal content when modal window is closed.
    projectActionsModal.off('hidden.bs.modal').on('hidden.bs.modal', function() {
      projectActionsModalHeader.html('');
      projectActionsModalBody.html('');
      projectActionsModalFooter.html('');
    });
  }

  // Initialize users editing modal remote loading.
  global.initUsersEditLink = function($el) {
    $el.find('.manage-users-link').off()
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

  /**
   * Initialize the JS for export projects modal to work.
   */
  function initExportProjectsModal() {
    exportProjectsBtn.off('click').click(function() {
      // Load HTML to refresh users list
      $.ajax({
        url: exportProjectsBtn.data('export-projects-modal-url'),
        type: 'GET',
        dataType: 'json',
        data: {
          project_ids: selectedProjects
        },
        success: function(data) {
          // Update modal title
          exportProjectsModalHeader.html(data.title);

          // Set modal body
          exportProjectsModalBody.html(data.html);

          // Update modal footer (show/hide buttons)
          if (data.status === 'error') {
            $('#export-projects-modal-close').show();
            $('#export-projects-modal-cancel').hide();
            exportProjectsSubmit.hide();
          } else {
            $('#export-projects-modal-close').hide();
            $('#export-projects-modal-cancel').show();
            exportProjectsSubmit.show();
          }
          // Show the modal
          exportProjectsModal.modal('show');
        },
        error: function() {
          // TODO
        }
      });
    });

    // Remove modal content when modal window is closed.
    exportProjectsModal.off().on('hidden.bs.modal', function() {
      exportProjectsModalHeader.html('');
      exportProjectsModalBody.html('');
    });
  }

  function initExportProjects() {
    // Submit the export projects
    exportProjectsSubmit.off('click').click(function() {
      $.ajax({
        url: exportProjectsSubmit.data('export-projects-submit-url'),
        type: 'POST',
        dataType: 'json',
        data: {
          project_ids: selectedProjects
        },
        success: function(data) {
          // Hide modal and show success flash
          exportProjectsModal.modal('hide');
          HelperModule.flashAlertMsg(data.flash, 'success');
        },
        error: function() {
          // TODO
        }
      });
    });
  }

  // Initialize reloading manage user modal content after posting new
  // user.

  function initAddUserForm() {
    projectActionsModalBody.find('.add-user-form').off()
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
    projectActionsModalBody.find('.remove-user-link').off()
      .on('ajax:success', function(e, data) {
        initUsersModalBody(data);
      });
  }

  //
  function initUserRoleForms() {
    projectActionsModalBody.find('.update-user-form select').off()
      .on('change', function() {
        $(this).parents('form').submit();
      });

    projectActionsModalBody.find('.update-user-form').off()
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

  function updateSelectedCards() {
    $('.panel-project').removeClass('selected');
    $('.project-card-selector').prop('checked', false);
    $.each(selectedProjects, function(index, value) {
      var selectedCard = $('.panel-project[id=' + value + ']');
      selectedCard.addClass('selected');
      selectedCard.find('.project-card-selector').prop('checked', true);
    });
  }

  /**
   * Initializes cards view
   */
  function init() {
    newProjectModal = $('#new-project-modal');
    newProjectModalForm = newProjectModal.find('form');
    newProjectModalBody = newProjectModal.find('.modal-body');
    newProjectBtn = $('.new-project-btn');

    editProjectModal = $('#edit-project-modal');
    editProjectModalTitle = editProjectModal.find('#edit-project-modal-label');
    editProjectModalBody = editProjectModal.find('.modal-body');
    editProjectBtn = editProjectModal.find(".btn[data-action='submit']");

    projectActionsModal = $('#project-actions-modal');
    projectActionsModalHeader = projectActionsModal.find('.modal-title');
    projectActionsModalBody = projectActionsModal.find('.modal-body');
    projectActionsModalFooter = projectActionsModal.find('.modal-footer');

    exportProjectsModal = $('#export-projects-modal');
    exportProjectsModalHeader = exportProjectsModal.find('.modal-title');
    exportProjectsModalBody = exportProjectsModal.find('.modal-body');
    exportProjectsBtn = $('#export-projects-button');
    exportProjectsSubmit = $('#export-projects-modal-submit');

    updateSelectedCards();
    initNewProjectModal();
    initEditProjectModal();
    initManageUsersModal();
    initExportProjectsModal();
    initExportProjects();

    initEditProjectButton($('.panel-project'));
    initArchiveRestoreButton($('.panel-project'));

    $('.project-card-selector').off('click').click(function() {
      var projectId = $(this).closest('.panel-project').data('id');
      // Determine whether ID is in the list of selected project IDs
      var index = $.inArray(projectId, selectedProjects);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (this.checked && index === -1) {
        $(this).closest('.panel-project').addClass('selected');
        selectedProjects.push(projectId);
        exportProjectsBtn.removeAttr('disabled');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        $(this).closest('.panel-project').removeClass('selected');
        selectedProjects.splice(index, 1);

        if (selectedProjects.length === 0) {
          exportProjectsBtn.attr('disabled', 'disabled');
        }
      }
    });

    // initialize project tab remote loading
    $('.panel-project .active').removeClass('active');
    $('.panel-project .panel-footer [role=tab]').off()
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
        parentNode.find('.active').removeClass('active');
        $this.parents('li').addClass('active');
        target.addClass('active');

        Comments.init('simple')
      })
      .on('ajax:error', function() {
        // TODO
      });
  }

  function refreshCurrentView() {
    if (projectsViewMode === 'cards') {
      loadCardsView();
    } else {
      TABLE.draw();
    }
    // Also refresh sidebar tree navigation
    $.ajax({
      url: $('#projects-cards-view').data('projects-sidebar-url'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        $('#slide-panel .tree').html('<ul>' + data.html + '</ul>');
        setupSidebarTree();
      }
    });
  }

  function loadCardsView() {
    // Load HTML with projects list
    var viewContainer = $('#projects-cards-view');
    animateSpinner(viewContainer, true);
    $.ajax({
      url: $('#projects-cards-view').data('projects-url'),
      type: 'GET',
      dataType: 'json',
      data: {
        filter: projectsViewFilter,
        sort: projectsViewSort
      },
      success: function(data) {
        viewContainer.html(data.html);
        if (data.count === 0 && projectsViewFilter !== 'archived') {
          $('#projects-present').hide();
          $('#projects-absent').show();
        } else {
          $('#projects-absent').hide();
          $('#projects-present').show();
        }
        initFormSubmitLinks(viewContainer);
        init();
      },
      error: function() {
        viewContainer.html('Error loading project list');
      }
    });
  }

  function initProjectsViewFilter() {
    $('.projects-view-filter').click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      if ($(this).data('filter') === projectsViewFilter) {
        return;
      }
      $('.projects-view-filter').removeClass('active');
      $(this).addClass('active');
      selectedProjects = [];
      projectsViewFilter = $(this).data('filter');
      projectsViewFilterChanged = true;
      if ($('#projects-cards-view').hasClass('active')) {
        loadCardsView();
      } else if (!$.isEmptyObject(TABLE)) {
        TABLE.draw();
      }
    });
  }

  function initProjectsViewModeSwitch() {
    $('input[name=projects-view-mode-selector]').off()
      .on('change', function() {
        if ($(this).val() === projectsViewMode) {
          return;
        }
        projectsViewMode = $(this).val();
        if (projectsChanged) {
          refreshCurrentView();
        }
        projectsChanged = false;
      })
      .on('click', function() {
        $(this).next().click();
      });
  }

  function initSorting() {
    $('#sortMenuDropdown a').click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      if (projectsViewSort !== $(this).data('sort')) {
        $('#sortMenuDropdown a').removeClass('disabled');
        projectsViewSort = $(this).data('sort');
        $('#sortMenu').html(I18n.t('general.sort.' + projectsViewSort + '_html'));
        loadCardsView();
        $(this).addClass('disabled');
        $('#sortMenu').dropdown('toggle');
      }
    });
  }

  // Updates "Select all" control in a data table
  function updateDataTableSelectAllCtrl() {
    var $table = TABLE.table().node();
    var $header = TABLE.table().header();
    var $chkboxAll = $('.project-row-selector', $table);
    var $chkboxChecked = $('.project-row-selector:checked', $table);
    var chkboxSelectAll = $('input[name="select_all"]', $header).get(0);

    // If none of the checkboxes are checked
    if ($chkboxChecked.length === 0) {
      chkboxSelectAll.checked = false;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If all of the checkboxes are checked
    } else if ($chkboxChecked.length === $chkboxAll.length) {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If some of the checkboxes are checked
    } else {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = true;
      }
    }
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('.dt-body-center .project-row-selector').change(function(e) {
      // Get row ID
      var $row = $(this).closest('tr');
      var data = TABLE.row($row).data();
      var rowId = data.DT_RowId;

      // Determine whether row ID is in the list of selected project IDs
      var index = $.inArray(rowId, selectedProjects);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (this.checked && index === -1) {
        selectedProjects.push(rowId);
        exportProjectsBtn.removeAttr('disabled');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        selectedProjects.splice(index, 1);

        if (selectedProjects.length === 0) {
          exportProjectsBtn.attr('disabled', 'disabled');
        }
      }

      updateDataTableSelectAllCtrl();
      e.stopPropagation();
    });

    // Handle click on "Select all" control
    $('.dataTables_scrollHead input[name="select_all"]').change(function(e) {
      if (this.checked) {
        $('.project-row-selector:not(:checked)').trigger('click');
      } else {
        $('.project-row-selector:checked').trigger('click');
      }
      // Prevent click event from propagating to parent
      e.stopPropagation();
    });
  }

  function updateSelectedRows() {
    TABLE.rows().every(function() {
      var rowSelector = $(this.node()).find('input[type="checkbox"]');
      var rowId = this.data().DT_RowId;

      if ($.inArray(rowId, selectedProjects) !== -1) {
        rowSelector.prop('checked', true);
      } else {
        rowSelector.prop('checked', false);
      }
    });

    updateDataTableSelectAllCtrl();
  }

  function dataTableInit() {
    var TABLE_ID = '#projects-overview-table';
    TABLE = $(TABLE_ID).DataTable({
      dom: "R<'row'<'col-sm-9-custom toolbar'l><'col-sm-3-custom'f>><'row'<'col-sm-12't>><'row'<'col-sm-7'i><'col-sm-5'p>>",
      stateSave: true,
      stateDuration: 0,
      processing: true,
      serverSide: true,
      scrollY: '64vh',
      scrollCollapse: true,
      destroy: true,
      ajax: {
        url: $(TABLE_ID).data('source'),
        global: false,
        type: 'POST',
        data: function(params) {
          params.filter = projectsViewFilter;
          // return { ...params, ...{ filter: projectsViewFilter } };
        }
      },
      colReorder: {
        fixedColumnsLeft: 9
      },
      columnDefs: [{
        // Checkbox column needs special handling
        targets: 0,
        searchable: false,
        orderable: false,
        className: 'dt-body-center',
        sWidth: '1%',
        render: function() {
          return "<input class='project-row-selector' type='checkbox'>";
        }
      }, {
        targets: 8,
        searchable: false,
        orderable: false,
        className: 'dt-body-center',
        sWidth: '1%'
      }],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      },
      rowCallback: function(row, data) {
        // Get row ID
        var rowId = data.DT_RowId;
        var dropdown = $(row).find('.dropdown');
        var dropdownCell = dropdown.closest('td');
        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, selectedProjects) !== -1) {
          $(row).find('input[type="checkbox"]').prop('checked', true);
        }

        initEditProjectButton($(row));
        initArchiveRestoreButton($(row));

        dropdown.off().on('show.bs.dropdown', function() {
          $('body').append(dropdown.css({
            left: dropdown.offset().left,
            position: 'absolute',
            top: dropdown.offset().top
          }).detach());
        });
        dropdown.off().on('hidden.bs.dropdown', function() {
          dropdownCell.append(dropdown.removeAttr('style').detach());
        });
      },
      order: [[2, 'asc']],
      columns: [
        { data: 'checkbox' },
        { data: 'status' },
        { data: 'name' },
        { data: 'start' },
        { data: 'visibility' },
        { data: 'users' },
        { data: 'experiments' },
        { data: 'tasks' },
        { data: 'actions' }
      ],
      fnDrawCallback: function() {
        animateSpinner(this, false);
        updateDataTableSelectAllCtrl();
        initRowSelection();
        initFormSubmitLinks($(this));
      },
      stateLoadCallback: function(settings, callback) {
        $.ajax({
          url: $(TABLE_ID).data('state-load-source'),
          dataType: 'json',
          type: 'GET',
          success: function(json) {
            callback(json.state);
          }
        });
      },
      stateSaveCallback: function() {
        // Don't do anything, state will be updated at backend, based on params
      }
    });

    // Handle click on table cells with checkboxes
    $(TABLE_ID).off().on('click', 'tbody td', function(e) {
      if ($(e.target).is(
        '.project-row-selector, .active-project-link, button, span'
      )) {
        // Skip if clicking on selector checkbox, links and buttons
        return;
      }
      $(this).parent().find('.project-row-selector').trigger('click');
    });

    return TABLE;
  }

  $('.projects-view-mode-switch a').off().on('shown.bs.tab', function(event) {
    if ($(event.target).data('mode') === 'table') {
      // table tab
      $('#sortMenu').hide();
      $('#projects-absent').hide();
      $('#projects-present').show();
      if ($.isEmptyObject(TABLE)) {
        dataTableInit();
      } else if (projectsViewFilterChanged) {
        TABLE.draw();
      } else {
        updateSelectedRows();
      }
    } else {
      // cards tab
      $('#sortMenu').show();
      if (projectsViewFilterChanged) {
        loadCardsView();
      }
      updateSelectedCards();
    }
    projectsViewFilterChanged = false;
  });

  initProjectsViewFilter();
  initProjectsViewModeSwitch();
  initSorting();
  loadCardsView();
}(window));

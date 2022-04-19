// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// TODO
// - error handling of assigning user to project, check XHR data.errors
// - error handling of removing user from project, check XHR data.errors
// - refresh project users tab after manage user modal is closed
// - refactor view handling using library, ex. backbone.js

/* global HelperModule dropdownSelector Sidebar Turbolinks filterDropdown InfiniteScroll GLOBAL_CONSTANTS */
/* eslint-disable no-use-before-define */

var ProjectsIndex = (function() {
  const PERMISSIONS = ['editable', 'archivable', 'restorable', 'moveable', 'deletable'];
  var projectsWrapper = '#projectsWrapper';
  var toolbarWrapper = '#toolbarWrapper';
  var cardsWrapper = '#cardsWrapper';
  var editProjectModal = '#edit-modal';
  var moveToModal = '#move-to-modal';
  var pageSize = GLOBAL_CONSTANTS.DEFAULT_ELEMENTS_PER_PAGE;

  var exportProjectsModal = null;
  var exportProjectsModalHeader = null;
  var exportProjectsModalBody = null;
  var exportProjectsBtn = '.export-projects-btn';
  var exportProjectsSubmit = '#export-projects-modal-submit';

  let projectsCurrentSort;
  let projectsViewSearch;
  let createdOnFromFilter;
  let createdOnToFilter;
  let membersFilter;
  let lookInsideFolders;
  let archivedOnFromFilter;
  let archivedOnToFilter;

  // Arrays with selected project and folder IDs shared between both views
  var selectedProjects = [];
  var selectedProjectFolders = [];
  var destinationFolder;

  // Init new project folder modal function
  function initNewProjectFolderModal() {
    var newProjectFolderModal = '#new-project-folder-modal';

    // Modal's submit handler function
    $(projectsWrapper)
      .on('ajax:success', newProjectFolderModal, function(ev, data) {
        $(newProjectFolderModal).modal('hide');
        HelperModule.flashAlertMsg(data.message, 'success');
        refreshCurrentView();
      })
      .on('ajax:error', newProjectFolderModal, function(e, data) {
        let form = $(this).find('form#new_project_folder');
        form.renderFormErrors('project_folder', data.responseJSON);
      });

    $(projectsWrapper)
      .on('ajax:success', '.new-project-folder-btn', function(e, data) {
        // Add and show modal
        $(projectsWrapper).append($.parseHTML(data.html));
        $(newProjectFolderModal).modal('show');
        $(newProjectFolderModal).find("input[type='text']").focus();
        // Remove modal when it gets closed
        $(newProjectFolderModal).on('hidden.bs.modal', function() {
          $(newProjectFolderModal).remove();
        });
      });
  }

  /**
   * Initialize the JS for new project modal to work.
   */
  function initNewProjectModal() {
    var newProjectModal = '#new-project-modal';

    // Modal's submit handler function
    $(projectsWrapper)
      .on('ajax:success', newProjectModal, function(ev, data) {
        $(newProjectModal).modal('hide');
        HelperModule.flashAlertMsg(data.message, 'success');
        refreshCurrentView();
      })
      .on('ajax:error', newProjectModal, function(ev, data) {
        $(this).renderFormErrors('project', data.responseJSON);
      });

    $(projectsWrapper)
      .on('ajax:success', '.new-project-btn', function(ev, data) {
        // Add and show modal
        $(projectsWrapper).append($.parseHTML(data.html));
        $(newProjectModal).modal('show');
        $(newProjectModal).find("input[type='text']").focus();
        // init select picker
        $(newProjectModal).find('.selectpicker').selectpicker();
        // Remove modal when it gets closed
        $(newProjectModal).on('hidden.bs.modal', function() {
          $(newProjectModal).remove();
        });
      });
  }

  // init delete project folders
  function initDeleteFoldersToolbarButton() {
    $(projectsWrapper)
      .on('ajax:before', '.delete-folders-btn', function() {
        let buttonForm = $(this);
        buttonForm.find('input[name="project_folders_ids[]"]').remove();
        selectedProjectFolders.forEach(function(id) {
          $('<input>').attr({
            type: 'hidden',
            name: 'project_folders_ids[]',
            value: id
          }).appendTo(buttonForm);
        });
      })
      .on('ajax:success', '.delete-folders-btn', function(ev, data) {
        // Add and show modal
        let deleteModal = $(data.html);
        $(projectsWrapper).append(deleteModal);
        deleteModal.modal('show');
        // Remove modal when it gets closed
        deleteModal.on('hidden.bs.modal', function() {
          $(this).remove();
        });
      });

    $(projectsWrapper)
      .on('ajax:success', '.delete-folders-form', function(ev, data) {
        $('.modal-project-folder-delete').modal('hide');
        HelperModule.flashAlertMsg(data.message, 'success');
        refreshCurrentView();
      })
      .on('ajax:error', '.delete-folders-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  // init project toolbar archive/restore functions
  function initArchiveRestoreToolbarButtons() {
    $(projectsWrapper)
      .on('ajax:before', '.archive-projects-form, .restore-projects-form', function() {
        let buttonForm = $(this);
        buttonForm.find('input[name="projects_ids[]"]').remove();
        selectedProjects.forEach(function(id) {
          $('<input>').attr({
            type: 'hidden',
            name: 'projects_ids[]',
            value: id
          }).appendTo(buttonForm);
        });
      })
      .on('ajax:success', '.archive-projects-form, .restore-projects-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.message, 'success');
        // Project saved, reload view
        refreshCurrentView();
      })
      .on('ajax:error', '.archive-projects-form, .restore-projects-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  // init project card archive/restore function
  function initArchiveRestoreButton() {
    $(projectsWrapper)
      .on('ajax:success', '.project-archive-restore-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.message, 'success');
        refreshCurrentView();
      })
      .on('ajax:error', '.project-archive-restore-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }
  /**
   * Initialize the JS for export projects modal to work.
   */
  function initExportProjectsModal() {
    $(projectsWrapper).on('click', exportProjectsBtn, function(ev) {
      ev.stopPropagation();
      ev.preventDefault();
      // Load HTML to refresh users list
      $.ajax({
        url: $(exportProjectsBtn).data('export-projects-modal-url'),
        type: 'GET',
        dataType: 'json',
        data: {
          project_ids: selectedProjects,
          project_folder_ids: selectedProjectFolders
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
            $(exportProjectsSubmit).hide();
          } else {
            $('#export-projects-modal-close').hide();
            $('#export-projects-modal-cancel').show();
            $(exportProjectsSubmit).show();
          }
          // Show the modal
          exportProjectsModal.modal('show');
        },
        error: function(data) {
          HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        }
      });
    });

    // Remove modal content when modal window is closed.
    exportProjectsModal.on('hidden.bs.modal', function() {
      exportProjectsModalHeader.html('');
      exportProjectsModalBody.html('');
    });
  }

  function initSelectAllCheckbox() {
    $(projectsWrapper).on('click', '.sci-checkbox.select-all', function() {
      var selectAll = this.checked;
      $.each($('.folder-card-selector, .project-card-selector'), function() {
        if (this.checked !== selectAll) this.click();
      });
    });
  }

  function initExportProjects() {
    // Submit the export projects
    $(exportProjectsSubmit).click(function() {
      $.ajax({
        url: $(exportProjectsSubmit).data('export-projects-submit-url'),
        type: 'POST',
        dataType: 'json',
        data: {
          project_ids: selectedProjects,
          project_folder_ids: selectedProjectFolders
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

  function updateSelectedCards() {
    $('.project-card').removeClass('selected');
    $.each(selectedProjects, function(index, value) {
      let selectedCard = $('.project-card[data-id="' + value + '"]');
      selectedCard.addClass('selected');
    });
  }

  function checkActionPermission(permission) {
    let allProjects;
    let allFolders;

    allProjects = selectedProjects.every(function(projectId) {
      return $(`.project-card[data-id="${projectId}"]`).data(permission);
    });

    allFolders = selectedProjectFolders.every(function(projectFolderId) {
      return $(`.folder-card[data-id="${projectFolderId}"]`).data(permission);
    });

    return allProjects && allFolders;
  }

  function updateProjectsToolbar() {
    let projectsToolbar = $('#projectsToolbar');

    if (selectedProjects.length === 0 && selectedProjectFolders.length === 0) {
      projectsToolbar.find('.single-object-action, .multiple-object-action').addClass('hidden');
    } else {
      if (selectedProjects.length + selectedProjectFolders.length === 1) {
        projectsToolbar.find('.single-object-action, .multiple-object-action').removeClass('hidden');
        if (selectedProjectFolders.length === 1) {
          projectsToolbar.find('.project-only-action').addClass('hidden');
        } else {
          projectsToolbar.find('.folders-only-action').addClass('hidden');
        }
      } else {
        projectsToolbar.find('.single-object-action').addClass('hidden');
        projectsToolbar.find('.multiple-object-action').removeClass('hidden');
        if (selectedProjectFolders.length > 0) {
          projectsToolbar.find('.project-only-action').addClass('hidden');
        }
        if (selectedProjects.length > 0) {
          projectsToolbar.find('.folder-only-action').addClass('hidden');
        }
      }
      PERMISSIONS.forEach((permission) => {
        if (!checkActionPermission(permission)) {
          projectsToolbar.find(`.btn[data-for="${permission}"]`).addClass('hidden');
        }
      });
    }
  }

  $('#content-wrapper').on('click', '.project-folder-link', function(event) {
    event.preventDefault();
    event.stopPropagation();
    $(cardsWrapper).data('projectsCardsUrl', $(this).data('projectsCardsUrl'));
    history.replaceState({}, '', this.href);
    $('.sidebar-container').data('sidebarUrl', $(this).data('sidebarUrl'));
    refreshCurrentView();
  });

  function refreshCurrentView() {
    loadCardsView();
    Sidebar.reload({
      sort: projectsCurrentSort,
      view_mode: $('.projects-index').data('view-mode')
    });
  }

  function initEditButton() {
    function loadEditModal(url) {
      $.get(url, function(result) {
        $(editProjectModal).find('.modal-content').html(result.html);
        $(editProjectModal).modal('show');
        $(editProjectModal).find('.selectpicker').selectpicker();
        $(editProjectModal).find('form')
          .on('ajax:success', function(ev, data) {
            $(editProjectModal).modal('hide');
            HelperModule.flashAlertMsg(data.message, 'success');
            refreshCurrentView();
          }).on('ajax:error', function(ev, data) {
            if ($(this).hasClass('edit_project')) {
              $(this).renderFormErrors('project', data.responseJSON.errors);
            } else {
              $(this).renderFormErrors('project_folder', data.responseJSON.errors);
            }
          });
      });
    }

    $(toolbarWrapper).on('click', '.edit-btn', function(ev) {
      var editUrl = $(`.project-card[data-id=${selectedProjects[0]}]`).data('edit-url') ||
        $(`.folder-card[data-id=${selectedProjectFolders[0]}]`).data('edit-url');
      ev.stopPropagation();
      ev.preventDefault();
      loadEditModal(editUrl);
    });

    $('.projects-container').on('click', '.edit-project-btn', function(ev) {
      var editUrl = $(this).attr('href');
      ev.stopPropagation();
      ev.preventDefault();
      loadEditModal(editUrl);
    });
  }

  function initMoveButton() {
    function initializeJSTree(foldersTree) {
      var timeOut = false;

      foldersTree.jstree({
        core: {
          multiple: false,
          themes: {
            dots: false,
            variant: 'large'
          }
        },
        search: {
          show_only_matches: true,
          show_only_matches_children: true
        },
        plugins: ['wholerow', 'search']
      });

      foldersTree.on('changed.jstree', function(e, data) {
        destinationFolder = data.instance.get_node(data.selected[0]).id.replace('folder_', '');
      });

      // Search timeout
      $('#searchFolderTree').keyup(function() {
        if (timeOut) { clearTimeout(timeOut); }
        timeOut = setTimeout(function() {
          foldersTree.jstree(true).search($('#searchFolderTree').val());
        }, 250);
      });
    }

    function loadMoveToModal(url) {
      let items;
      let projects;
      let folders;

      if ((selectedProjects.length) && (selectedProjectFolders.length)) {
        items = 'project_and_folders';
      } else if (selectedProjectFolders.length) {
        items = 'folders';
      } else {
        items = 'projects';
      }
      projects = selectedProjects.map(e => ({ id: e, type: 'project' }));
      folders = selectedProjectFolders.map(e => ({ id: e, type: 'project_folder' }));
      let movables = projects.concat(folders);

      $.get(url, { items: items, sort: projectsCurrentSort, view_mode: $('.projects-index').data('view-mode') }, function(result) {
        $(moveToModal).find('.modal-content').html(result.html);
        $(moveToModal).modal('show');
        initializeJSTree($(moveToModal).find('#moveToFolders'));

        $(moveToModal).find('form')
          .on('ajax:before', function() {
            $('<input>').attr({
              type: 'hidden',
              name: 'destination_folder_id',
              value: destinationFolder
            }).appendTo($(this));

            $('<input>').attr({
              type: 'hidden',
              name: 'movables',
              value: JSON.stringify(movables)
            }).appendTo($(this));
          })
          .on('ajax:success', function(ev, data) {
            $(moveToModal).modal('hide');
            HelperModule.flashAlertMsg(data.flash, 'success');
            refreshCurrentView();
          })
          .on('ajax:error', function(ev, data) {
            $(moveToModal).modal('hide');
            HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
          });
      });
    }

    $(projectsWrapper).on('click', '.move-projects-btn', function(e) {
      e.preventDefault();
      loadMoveToModal($(this).data('url'));
    });
  }

  function loadPlaceHolder() {
    let palceholder = '';
    $.each(Array(pageSize), function() {
      palceholder += $('#projectPlaceholder').html();
    });
    $(palceholder).insertAfter($(cardsWrapper).find('.table-header'));
  }

  function loadCardsView() {
    var requestParams = {
      view_mode: $('.projects-index').data('view-mode'),
      sort: projectsCurrentSort,
      search: projectsViewSearch,
      members: membersFilter,
      created_on_from: createdOnFromFilter,
      created_on_to: createdOnToFilter,
      folders_search: lookInsideFolders,
      archived_on_from: archivedOnFromFilter,
      archived_on_to: archivedOnToFilter
    };
    var viewContainer = $(cardsWrapper);
    var cardsUrl = viewContainer.data('projects-cards-url');

    loadPlaceHolder();
    $.ajax({
      url: cardsUrl,
      type: 'GET',
      dataType: 'json',
      data: { ...requestParams, ...{ page: 1 } },
      success: function(data) {
        $('#breadcrumbsWrapper').html(data.breadcrumbs_html);
        $(projectsWrapper).find('.projects-title').html(data.title);
        $(toolbarWrapper).html(data.toolbar_html);
        viewContainer.data('projects-cards-url', data.projects_cards_url);
        viewContainer.removeClass('no-results');
        viewContainer.find('.card, .projects-group, .no-results-container').remove();
        viewContainer.append(data.cards_html);
        if (viewContainer.find('.no-results-container').length) {
          viewContainer.addClass('no-results');
        }
        selectedProjects.length = 0;
        selectedProjectFolders.length = 0;
        updateProjectsToolbar();
        if (data.filtered) {
          InfiniteScroll.removeScroll(cardsWrapper);
        } else {
          InfiniteScroll.init(cardsWrapper, {
            url: cardsUrl,
            eventTarget: window,
            placeholderTemplate: '#projectPlaceholder',
            endOfListTemplate: '#projectEndOfList',
            pageSize: pageSize,
            customResponse: (response) => {
              $(response.cards_html).appendTo(cardsWrapper);
            },
            customParams: (params) => {
              return { ...params, ...requestParams };
            }
          });
        }
      },
      error: function() {
        viewContainer.html('Error loading project list');
      }
    });
  }

  function initProjectsViewModeSwitch() {
    let projectsPageSelector = '.projects-index';

    $(projectsPageSelector)
      .on('ajax:success', '.change-projects-view-type-form', function(ev, data) {
        $(cardsWrapper).removeClass('list').addClass(data.cards_view_type_class);
        $(projectsPageSelector).find('.cards-switch .button-to').removeClass('selected');
        $(ev.target).find('.button-to').addClass('selected');
        $(ev.target).parents('.dropdown.view-switch').removeClass('open');
        InfiniteScroll.loadMore(cardsWrapper);
      })
      .on('ajax:error', '.change-projects-view-type-form', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
      });

    // Active/Archived switch
    // We have different sorting, filters for active/archived views.
    // With turbolinks visit all those elements are updated.
    $(projectsPageSelector).on('click', '.archive-switch', function() {
      $(projectsPageSelector).find('.projects-container').remove();
      Turbolinks.visit($(this).data('url'));
    });
  }

  function initSorting() {
    $('#sortMenuDropdown a').click(function() {
      if (projectsCurrentSort !== $(this).data('sort')) {
        $('#sortMenuDropdown a').removeClass('selected');
        projectsCurrentSort = $(this).data('sort');
        refreshCurrentView();
        $(this).addClass('selected');
        $('#sortMenu').dropdown('toggle');
      }
    });
  }

  function selectDate($field) {
    var datePicker = $field.data('DateTimePicker');
    if (datePicker && datePicker.date()) {
      return datePicker.date()._d.toUTCString();
    }
    return null;
  }

  function initProjectsFilters() {
    var $filterDropdown = filterDropdown.init();
    let $projectsFilter = $('.projects-index .projects-filters');
    let $membersFilter = $('.members-filter', $projectsFilter);
    let $foldersCB = $('#folder_search', $projectsFilter);
    let $createdOnFromFilter = $('.created-on-filter .from-date', $projectsFilter);
    let $createdOnToFilter = $('.created-on-filter .to-date', $projectsFilter);
    let $archivedOnFromFilter = $('.archived-on-filter .from-date', $projectsFilter);
    let $archivedOnToFilter = $('.archived-on-filter .to-date', $projectsFilter);
    let $textFilter = $('#textSearchFilterInput', $projectsFilter);

    function appliedFiltersMark() {
      let filtersEnabled = projectsViewSearch
        || createdOnFromFilter
        || createdOnToFilter
        || (membersFilter && membersFilter.length !== 0)
        || lookInsideFolders
        || archivedOnFromFilter
        || archivedOnToFilter;
      filterDropdown.toggleFilterMark($filterDropdown, filtersEnabled);
    }

    dropdownSelector.init($membersFilter, {
      optionClass: 'checkbox-icon users-dropdown-list',
      optionLabel: (data) => {
        return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
      },
      tagLabel: (data) => {
        return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
      },
      labelHTML: true,
      tagClass: 'users-dropdown-list'
    });

    $projectsFilter.on('click', '#folderSearchInfoBtn', function(e) {
      e.stopPropagation();
      $('#folderSearchInfo').toggle();
    });

    $projectsFilter.on('click', '#folder_search', function(e) {
      e.stopPropagation();
    });

    $filterDropdown.on('filter:apply', function() {
      createdOnFromFilter = selectDate($createdOnFromFilter);
      createdOnToFilter = selectDate($createdOnToFilter);
      membersFilter = dropdownSelector.getValues($('.members-filter'));
      lookInsideFolders = $foldersCB.prop('checked') ? 'true' : '';
      archivedOnFromFilter = selectDate($archivedOnFromFilter);
      archivedOnToFilter = selectDate($archivedOnToFilter);
      projectsViewSearch = $textFilter.val();

      appliedFiltersMark();
      refreshCurrentView();
    });

    // Clear filters
    $filterDropdown.on('filter:clear', function() {
      dropdownSelector.clearData($membersFilter);
      if ($createdOnFromFilter.data('DateTimePicker')) $createdOnFromFilter.data('DateTimePicker').clear();
      if ($createdOnToFilter.data('DateTimePicker')) $createdOnToFilter.data('DateTimePicker').clear();
      if ($archivedOnFromFilter.data('DateTimePicker')) $archivedOnFromFilter.data('DateTimePicker').clear();
      if ($archivedOnToFilter.data('DateTimePicker')) $archivedOnToFilter.data('DateTimePicker').clear();
      $foldersCB.prop('checked', false);
      $textFilter.val('');
    });

    // Prevent filter window close
    $filterDropdown.on('filter:clickBody', function() {
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
      dropdownSelector.closeDropdown($membersFilter);
      $('#folderSearchInfo').hide();
    });
  }

  /**
   * Initializes cards view
   */
  function init() {
    exportProjectsModal = $('#export-projects-modal');
    exportProjectsModalHeader = exportProjectsModal.find('.modal-title');
    exportProjectsModalBody = exportProjectsModal.find('.modal-body');

    updateSelectedCards();
    initNewProjectFolderModal();
    initNewProjectModal();
    initExportProjectsModal();
    initExportProjects();
    initDeleteFoldersToolbarButton();
    initArchiveRestoreToolbarButtons();
    initEditButton();
    initMoveButton();
    initProjectsViewModeSwitch();
    initSorting();
    initSelectAllCheckbox();
    initProjectsFilters();
    initArchiveRestoreButton();
    loadCardsView();

    $(projectsWrapper).on('click', '.folder-card-selector', function() {
      let folderCard = $(this).closest('.folder-card');
      let folderId = folderCard.data('id');
      let index = $.inArray(folderId, selectedProjectFolders);

      // If checkbox is checked and row ID is not in list of selected folder IDs
      if (this.checked && index === -1) {
        selectedProjectFolders.push(folderId);
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        selectedProjectFolders.splice(index, 1);
      }

      updateProjectsToolbar();
    });

    $(projectsWrapper).on('click', '.project-card-selector', function() {
      let projectCard = $(this).closest('.project-card');
      let projectId = projectCard.data('id');
      // Determine whether ID is in the list of selected project IDs
      let index = $.inArray(projectId, selectedProjects);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (this.checked && index === -1) {
        $(this).closest('.project-card').addClass('selected');
        selectedProjects.push(projectId);
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        $(this).closest('.project-card').removeClass('selected');
        selectedProjects.splice(index, 1);
      }

      updateProjectsToolbar();
    });
  }

  init();

  return {
    loadCardsView: loadCardsView
  };
}());

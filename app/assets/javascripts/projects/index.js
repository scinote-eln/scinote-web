// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// TODO
// - error handling of assigning user to project, check XHR data.errors
// - error handling of removing user from project, check XHR data.errors
// - refresh project users tab after manage user modal is closed
// - refactor view handling using library, ex. backbone.js

/* global Comments CounterBadge animateSpinner initFormSubmitLinks HelperModule
   I18n dropdownSelector Sidebar */

(function(global) {
  var newProjectModal = null;
  var newProjectModalForm = null;
  var newProjectModalBody = null;
  var newProjectBtn = null;

  var editProjectModal = '#edit-modal';

  var projectActionsModal = null;
  var projectActionsModalHeader = null;
  var projectActionsModalBody = null;
  var projectActionsModalFooter = null;

  var exportProjectsModal = null;
  var exportProjectsModalHeader = null;
  var exportProjectsModalBody = null;
  var exportProjectsBtn = null;
  var exportProjectsSubmit = null;

  var projectsViewSearch;
  var projectsChanged = false;
  var projectsViewSort = $('#sortMenuDropdown a.disabled').data('sort');

  // Arrays with selected project and folder IDs shared between both views
  var selectedProjects = [];
  var selectedProjectFolders = [];

  // Init new project folder modal function
  function initNewProjectFolderModal() {
    var newProjectFolderModal = '#new-project-folder-modal';
    // Modal's submit handler function
    function newProjectFolderModalResponse() {
      $(newProjectFolderModal).find('form')
        .on('ajax:success', function(ev, data) {
          refreshCurrentView();
          $(newProjectFolderModal).modal('hide');
          HelperModule.flashAlertMsg(data.message, 'success');
        })
        .on('ajax:error', function(e, data) {
          $(this).renderFormErrors('project_folder', data.responseJSON);
        });
    }

    $('.new-project-folder-btn')
      .on('ajax:success', function(e, data) {
        // Add and show modal
        $('body').append($.parseHTML(data.html));
        $(newProjectFolderModal).modal('show');
        $(newProjectFolderModal).find("input[type='text']").focus();
        newProjectFolderModalResponse();

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

  function initManageUsersModal() {
    // Reload users tab HTML element when modal is closed
    projectActionsModal.off('hide.bs.modal').on('hide.bs.modal', function() {
      refreshCurrentView();
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

  function refreshProjectsToolbar() {
    let projectsToolbar = $('#projectsToolbar');

    if (selectedProjects.length === 0 && selectedProjectFolders.length === 0) {
      projectsToolbar.find('.single-object-action, .multiple-object-action').addClass('hidden');
      projectsToolbar.find('.new-object-actions').removeClass('hidden');
    } else if (selectedProjects.length + selectedProjectFolders.length === 1) {
      projectsToolbar.find('.new-object-actions').addClass('hidden');
      projectsToolbar.find('.single-object-action, .multiple-object-action').removeClass('hidden');
    } else {
      projectsToolbar.find('.new-object-actions').addClass('hidden');
      projectsToolbar.find('.single-object-action').addClass('hidden');
      projectsToolbar.find('.multiple-object-action').removeClass('hidden');
    }
  }

  $('#wrapper').on('click', '.project-folder-link', function(event) {
    event.preventDefault();
    event.stopPropagation();
    let viewContainer = $('#cards-wrapper');
    viewContainer.data('projects-cards-url', $(this).data('projectsCardsUrl'));
    history.replaceState({}, '', this.href);
    $('.sidebar-container').data('sidebar-url', $(this).data('sidebar-url'));
    refreshCurrentView();
  });

  /**
   * Initializes cards view
   */
  function init() {
    newProjectModal = $('#new-project-modal');
    newProjectModalForm = newProjectModal.find('form');
    newProjectModalBody = newProjectModal.find('.modal-body');
    newProjectBtn = $('.new-project-btn');

    projectActionsModal = $('#project-actions-modal');
    projectActionsModalHeader = projectActionsModal.find('.modal-title');
    projectActionsModalBody = projectActionsModal.find('.modal-body');
    projectActionsModalFooter = projectActionsModal.find('.modal-footer');

    exportProjectsModal = $('#export-projects-modal');
    exportProjectsModalHeader = exportProjectsModal.find('.modal-title');
    exportProjectsModalBody = exportProjectsModal.find('.modal-body');
    exportProjectsBtn = $('.export-projects-btn');
    exportProjectsSubmit = $('#export-projects-modal-submit');

    updateSelectedCards();
    initNewProjectFolderModal();
    initNewProjectModal();
    initManageUsersModal();
    initExportProjectsModal();
    initExportProjects();

    initFormSubmitLinks($('.project-card'));
    initArchiveRestoreButton($('.project-card'));
    initUsersEditLink($('.project-card'));

    $('#cards-wrapper').on('click', '.folder-card-selector', function() {
      let folderCard = $(this).closest('.folder-card');
      let folderId = folderCard.data('id');
      let index = $.inArray(folderId, selectedProjectFolders);

      // If checkbox is checked and row ID is not in list of selected folder IDs
      if (this.checked && index === -1) {
        selectedProjectFolders.push(folderId);
        exportProjectsBtn.removeAttr('disabled');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        selectedProjectFolders.splice(index, 1);
      }

      refreshProjectsToolbar();
    });

    $('#cards-wrapper').on('click', '.project-card-selector', function() {
      let projectsToolbar = $('#projectsToolbar');
      let projectCard = $(this).closest('.project-card');
      let projectId = projectCard.data('id');
      // Determine whether ID is in the list of selected project IDs
      let index = $.inArray(projectId, selectedProjects);

      // If checkbox is checked and row ID is not in list of selected project IDs
      if (this.checked && index === -1) {
        $(this).closest('.panel-project').addClass('selected');
        selectedProjects.push(projectId);
        exportProjectsBtn.removeAttr('disabled');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
      } else if (!this.checked && index !== -1) {
        $(this).closest('.panel-project').removeClass('selected');
        selectedProjects.splice(index, 1);
      }

      refreshProjectsToolbar();

      selectedProjects.forEach(function(id) {
        if ($('#projects-cards-view').find(`.panel-project[data-id="${id}"]`).hasClass('project-folder')) {
          projectsToolbar.find('.project-only-action').attr('disabled', true);
        }
      });
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
    loadCardsView();
    Sidebar.reload();
  }

  function initEditButton() {
    function loadEditModal(url) {
      $.get(url, function(result) {
        $(editProjectModal).find('.modal-content').html(result.html);
        $(editProjectModal).modal('show');
        $(editProjectModal).find('form')
          .on('ajax:success', function(ev, data) {
            $(editProjectModal).modal('hide');
            HelperModule.flashAlertMsg(data.message, 'success');
            refreshCurrentView();
          }).on('ajax:error', function(ev, data) {
            HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
            $(this).renderFormErrors('project', data.responseJSON.errors);
            $(this).renderFormErrors('project_folder', data.responseJSON.errors);
          });
      });
    }

    $('.project-actions .edit-btn').on('click', function(e) {
      var editUrl = $(`.project-card[data-id=${selectedProjects[0]}]`).data('edit-url') ||
        $(`.folder-card[data-id=${selectedProjectFolders[0]}]`).data('edit-url');
      e.preventDefault();
      loadEditModal(editUrl);
    });

    $('.projects-container').on('click', '.edit-project-btn', function(e) {
      var editUrl = $(this).attr('href');
      e.preventDefault();
      loadEditModal(editUrl);
    });
  }

  function loadCardsView() {
    // Load HTML with projects list
    var viewContainer = $('#cards-wrapper');
    // animateSpinner(viewContainer, true);

    $.ajax({
      url: viewContainer.data('projects-cards-url'),
      type: 'GET',
      dataType: 'json',
      data: {
        filter: $('.projects-index').data('mode'),
        sort: projectsViewSort,
        search: projectsViewSearch
      },
      success: function(data) {
        $('#breadcrumbs-wrapper').html(data.breadcrumbs_html);
        viewContainer.data('projects-cards-url', data.projects_cards_url);
        viewContainer.find('.card, .projects-group').remove();
        viewContainer.append(data.cards_html);
        selectedProjects.length = 0;
        selectedProjectFolders.length = 0;
        refreshProjectsToolbar();
        init();
      },
      error: function() {
        viewContainer.html('Error loading project list');
      }
    });
  }

  function initProjectsViewModeSwitch() {
    let projectsPageSelector = '.projects-index';

    // list/cards switch
    $(projectsPageSelector).on('click', '.projects-view-mode', function() {
      let $btn = $(this);
      $('.projects-view-mode').removeClass('active');
      if ($btn.hasClass('view-switch-cards')) {
        $('#cards-wrapper').removeClass('list');
      } else if ($btn.hasClass('view-switch-list')) {
        $('#cards-wrapper').addClass('list');
      }
      $btn.addClass('active');
    });

    // active/archived switch
    $(projectsPageSelector).on('click', '.archive-switch', function() {
      $(projectsPageSelector).toggleClass('archived active').data('mode', $(this).data('mode'));
      refreshCurrentView();
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

  function initProjectsFilter() {
    let $projectsFilter = $('.projects-index .projects-filters');
    let $membersFilter = $('.members-filter', $projectsFilter);
    let $foldersCB = $('#folder_search', $projectsFilter);
    let $createdOnStartFilter = $('#createdOnStartDate', $projectsFilter);
    let $createdOnEndFilter = $('#createdOnEndDate', $projectsFilter);
    let $archivedOnStartFilter = $('#archivedOnStartDate', $projectsFilter);
    let $archivedOnEndFilter = $('#archivedOnEndDate', $projectsFilter);
    let $textFilter = $('#textSearchFilterInput', $projectsFilter);

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

    $textFilter.click((e) => {
      e.stopPropagation();
      $('#textSearchFilterHistory').toggle();
      $textFilter.closest('.dropdown').toggleClass('open');
    }).on('input', () => {
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
    });

    $projectsFilter.on('click', '.projects-search-keyword', function(e) {
      e.stopPropagation();
      e.preventDefault();
      $textFilter.val($(this).data('keyword'));
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
    });

    $projectsFilter.on('click', '#folderSearchInfoBtn', function(e) {
      e.stopPropagation();
      $('#folderSearchInfo').toggle();
    });

    $('.project-filters-dropdown').on('show.bs.dropdown', function() {
      let teamId = $projectsFilter.data('team-id');
      $('#textSearchFilterHistory').find('li').remove();

      try {
        let storagePath = `project_filters_per_team/${teamId}/recent_search_keywords`;
        let recentSearchKeywords = JSON.parse(localStorage.getItem(storagePath));
        $.each(recentSearchKeywords, function(i, keyword) {
          $('#textSearchFilterHistory').append($(
            `<li class="dropdown-item">
              <a class="projects-search-keyword" href="#" data-keyword="${keyword}">
                <i class="fas fa-history"></i>
                <span class="keyword-text">${keyword}</span>
              </a>
            </li>`
          ));
        });
      } catch (error) {
        console.error(error);
      }
    }).on('hide.bs.dropdown', function() {
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
      $('#folderSearchInfo').hide();
    });

    $('#applyProjectFiltersButton').click((e) => {
      e.stopPropagation();
      e.preventDefault();

      let teamId = $('.projects-filters').data('team-id');
      projectsViewSearch = $('#textSearchFilterInput').closest('.select-block').find('input[type=text]').val();
      try {
        let storagePath = `project_filters_per_team/${teamId}/recent_search_keywords`;
        let recentSearchKeywords = JSON.parse(localStorage.getItem(storagePath));
        if (!Array.isArray(recentSearchKeywords)) recentSearchKeywords = [];
        if (recentSearchKeywords.indexOf(projectsViewSearch) !== -1) {
          recentSearchKeywords.splice(recentSearchKeywords.indexOf(projectsViewSearch), 1);
        }
        if (recentSearchKeywords.length > 4) {
          recentSearchKeywords = recentSearchKeywords.slice(0, 4);
        }
        recentSearchKeywords.unshift(projectsViewSearch);
        localStorage.setItem(storagePath, JSON.stringify(recentSearchKeywords));
      } catch (error) {
        console.error(error);
      }

      $('.projects-filters').dropdown('toggle');

      loadCardsView();
    });

    // Clear filters
    $('.clear-button', $projectsFilter).click((e) => {
      e.stopPropagation();
      e.preventDefault();

      dropdownSelector.clearData($membersFilter);
      if ($createdOnStartFilter.data('DateTimePicker')) $createdOnStartFilter.data('DateTimePicker').clear();
      if ($createdOnEndFilter.data('DateTimePicker')) $createdOnEndFilter.data('DateTimePicker').clear();
      if ($archivedOnStartFilter.data('DateTimePicker')) $archivedOnStartFilter.data('DateTimePicker').clear();
      if ($archivedOnEndFilter.data('DateTimePicker')) $archivedOnEndFilter.data('DateTimePicker').clear();
      $foldersCB.prop('checked', false);
      $textFilter.val('');
    });

    // Prevent filter window close
    $($projectsFilter).click((e) => {
      if (!$(e.target).is('input,a')) {
        e.stopPropagation();
        e.preventDefault();
        $('#textSearchFilterHistory').hide();
        $textFilter.closest('.dropdown').removeClass('open');
        dropdownSelector.closeDropdown($membersFilter);
        $('#folderSearchInfo').hide();
      }
    });
  }

  initEditButton();
  initProjectsViewModeSwitch();
  initSorting();
  loadCardsView();
  initProjectsFilter();
}(window));

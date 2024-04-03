/* global HelperModule PerfectScrollbar */

// eslint-disable-next-line func-names
window.ShareModal = (function() {
  function init() {
    var form = $('.share-repo-modal').find('form');
    var sharedCBs = form.find("input[name='share_team_ids[]']");
    var permissionCBs = form.find("input[name='write_permissions[]']");
    var permissionChanges = form.find("input[name='permission_changes']");
    var submitBtn = form.find('input[type="submit"]');
    var selectAllCheckbox = form.find('.all-teams .sci-checkbox');

    form.find('.teams-list').find('input.sci-checkbox, .permission-selector')
      .toggleClass('hidden', selectAllCheckbox.is(':checked'));
    form.find('.all-teams .sci-toggle-checkbox')
      .toggleClass('hidden', !selectAllCheckbox.is(':checked'));

    selectAllCheckbox.change(function() {
      form.find('.teams-list').find('input.sci-checkbox, .permission-selector')
        .toggleClass('hidden', this.checked);
      form.find('.all-teams .sci-toggle-checkbox').toggleClass('hidden', !this.checked);
    });

    sharedCBs.change(function() {
      var selectedTeams = form.find('.teams-list .sci-checkbox:checked').length;
      form.find('#select_all_teams').prop('indeterminate', selectedTeams > 0);
      $('#editable_' + this.value).toggleClass('hidden', !this.checked);
    });

    if (form.find('.teams-list').length) new PerfectScrollbar(form.find('.teams-list')[0]);

    permissionCBs.change(function() {
      var changes = JSON.parse(permissionChanges.val());
      changes[this.value] = 'true';
      permissionChanges.val(JSON.stringify(changes));
    });

    submitBtn.on('click', function(event) {
      event.preventDefault();
      $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: form.serialize(),
        success: function(data) {
          if (data.warnings) {
            alert(data.warnings);
          }
          $(`#slide-panel li.active .repository-share-status,
             #repository-toolbar .repository-share-status
          `).toggleClass('hidden', !data.status);
          HelperModule.flashAlertMsg(form.data('success-message'), 'success');
          $('.share-repo-modal').modal('hide');
        },
        error: function(data) {
          alert(data.responseJSON.errors);
          $('.share-repo-modal').modal('hide');
        }
      });
    });
  }

  return {
    init: init
  };
}());

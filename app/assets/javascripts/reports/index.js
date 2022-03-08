(function () {

  var newReportModal = null;
  var newReportModalBody = null;
  var newReportCreateButton = null;

  var deleteReportsModal = null;
  var deleteReportsInput = null;

  var newReportButton = null;
  var editReportButton = null;
  var deleteReportsButton = null;
  var checkAll = null;
  var allChecks = null;
  var allRows = null;

  var checkedReports = [];

  /**
   * Initializes page
   */
  function init() {
    // Initialize selectors
    newReportModal = $('#new-report-modal');
    newReportModalBody = newReportModal.find('.modal-body');
    newReportCreateButton = $('#create-new-report-btn');
    deleteReportsModal = $('#delete-reports-modal');
    deleteReportsInput = $('#report-ids');
    newReportButton = $('#new-report-btn');
    editReportButton = $('#edit-report-btn');
    deleteReportsButton = $('#delete-reports-btn');
    checkAll = $('.check-all-reports');
    allChecks = $('.check-report');
    allRows = $('.report-row');

    initNewReportModal();
    initCheckboxesAndEditing();
    updateButtons();
    initEditReport();
    initDeleteReports();
    initTutorial();
  }

  /**
   * Initialize the new report modal.
   */
  function initNewReportModal() {
    // TEMPORARY DISABLED
    /**
    // Remove modal content when modal window is closed.
    newReportModal.on("hidden.bs.modal", function () {
      newReportModalBody.html("");
    });

    // Populate modal content when AJAX call is complete
    newReportButton
    .on("ajax:before", function () {
      newReportModal.modal('show');
    })
    .on("ajax:success", function (e, data) {
      newReportModalBody.html(data.html);
    });

    // Before redirecting, pass parameters
    newReportCreateButton.click(function(event){
      var url = $(this).closest("form").attr("action");

      event.preventDefault();

      // Copy the GET params
      var val = newReportModalBody.find(".btn-primary.active > input[type='radio']").attr("value");
      url += "/" + val;

      $(location).attr("href", url);
      return false;
    });
    */
  }

  /**
   * Initialize interaction between checkboxes, editing and deleting.
   */
  function initCheckboxesAndEditing() {
    checkAll.click(function() {
      allChecks.prop("checked", this.checked);
      checkedReports = [];
      if (this.checked) {
        _.each(allRows, function(row) {
          checkedReports.push($(row).data("id"));
        });
      }

      updateButtons();
    });
    allChecks.click(function() {
      checkAll.prop("checked", false);
      var id = $(this).closest(".report-row").data("id");
      if (this.checked) {
        if (_.indexOf(checkedReports, id) === -1) {
          checkedReports.push(id);
        }
      } else {
        var idx = _.indexOf(checkedReports, id);
        if (idx !== -1) {
          checkedReports.splice(idx, 1);
        }
      }

      updateButtons();
    });
  }

  /**
   * Update edit & delete buttons depending on checking of reports.
   */
  function updateButtons() {
    if (checkedReports.length === 0) {
      editReportButton.addClass("disabled");
      deleteReportsButton.addClass("disabled");
    } else if (checkedReports.length === 1) {
      editReportButton.removeClass("disabled");
      deleteReportsButton.removeClass("disabled");
    } else {
      editReportButton.addClass("disabled");
      deleteReportsButton.removeClass("disabled");
    }
  }

  /**
   * Initialize the edit report functionality.
   */
  function initEditReport() {
    editReportButton.click(function(e) {
      animateLoading();
      if (checkedReports.length === 1) {
        var id = checkedReports[0];
        var row = $(".report-row[data-id='" + id + "']");
        var url = row.data("edit-link");

        $(location).attr("href", url);
      }

      return false;
    });
  }

  /**
   * Initialize the deleting of reports.
   */
  function initDeleteReports() {
    deleteReportsButton.click(function(e) {
      if (checkedReports.length > 0) {
        // Copy the checked IDs into the hidden input
        deleteReportsInput.attr("value", "[" + checkedReports + "]");

        // Show modal
        deleteReportsModal.modal("show");
      }
    });

    $("#confirm-delete-reports-btn").click(function(e) {
      animateLoading();
    });
  }

  /**
   * Initializes tutorial
   */
  function initTutorial() {
    var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
    if (stepNum === 19) {
      var newReportBtn = $('#new-report-btn');

      var nextPage = newReportBtn.attr('href');
      var steps = [{
        element: newReportBtn[0],
        intro: I18n.t('tutorial.reports_index_click_new_report_html'),
        position: 'right'
      }];
      initPageTutorialSteps(19, 19, nextPage, function() {}, function() {},
       steps);
    }
  }

  $(document).ready(init);
}());

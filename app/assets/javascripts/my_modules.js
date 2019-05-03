// Bind ajax for editing descriptions
function bindEditDescriptionAjax() {
  var editDescriptionModal = $("#manage-module-description-modal");
  var editDescriptionModalBody = editDescriptionModal.find(".modal-body");
  var editDescriptionModalSubmitBtn = editDescriptionModal.find("[data-action='submit']");
  $(".description-link")
  .on("ajax:success", function (ev, data, status) {
    var descriptionLink = $(".description-refresh");

    // Set modal body & title
    editDescriptionModalBody.html(data.html);
    editDescriptionModal
    .find("#manage-module-description-modal-label")
    .text(data.title);

    editDescriptionModalBody.find("form")
    .on("ajax:success", function (ev2, data2, status2) {
      // Update module's description in the tab
      descriptionLink.html(data2.description_label);

      // Close modal
      editDescriptionModal.modal("hide");
    })
    .on("ajax:error", function (ev2, data2, status2) {
      // Display errors if needed
      $(this).renderFormErrors("my_module", data.responseJSON);
    });

    // Show modal
    editDescriptionModal.modal("show");
  })
  .on("ajax:error", function (ev, data, status) {
    // TODO
  });

  editDescriptionModalSubmitBtn.on("click", function () {
    // Submit the form inside the modal
    editDescriptionModalBody.find("form").submit();
  });

  editDescriptionModal.on("hidden.bs.modal", function () {
    editDescriptionModalBody.find("form").off("ajax:success ajax:error");
    editDescriptionModalBody.html("");
  });
}

// Bind ajax for editing due dates
function bindEditDueDateAjax() {
  var editDueDateModal = null;
  var editDueDateModalBody = null;
  var editDueDateModalTitle = null;
  var editDueDateModalSubmitBtn = null;

  editDueDateModal = $("#manage-module-due-date-modal");
  editDueDateModalBody = editDueDateModal.find(".modal-body");
  editDueDateModalTitle = editDueDateModal.find("#manage-module-due-date-modal-label");
  editDueDateModalSubmitBtn = editDueDateModal.find("[data-action='submit']");

  $(".due-date-link")
  .on("ajax:success", function (ev, data, status) {
    var dueDateLink = $('.task-due-date');

    // Load contents
    editDueDateModalBody.html(data.html);
    editDueDateModalTitle.text(data.title);

    // Add listener to form inside modal
    editDueDateModalBody.find("form")
    .on("ajax:success", function (ev2, data2, status2) {
      // Update module's due date
      dueDateLink.html(data2.module_header_due_date_label);

      // Close modal
      editDueDateModal.modal("hide");
    })
    .on("ajax:error", function (ev2, data2, status2) {
      // Display errors if needed
      $(this).renderFormErrors("my_module", data.responseJSON);
    });

    // Open modal
    editDueDateModal.modal("show");
  })
  .on("ajax:error", function (ev, data, status) {
    // TODO
  });

  editDueDateModalSubmitBtn.on("click", function () {
    // Submit the form inside the modal
    editDueDateModalBody.find("form").submit();
  });

  editDueDateModal.on("hidden.bs.modal", function () {
    editDueDateModalBody.find("form").off("ajax:success ajax:error");
    editDueDateModalBody.html("");
  });
}

// Bind ajax for editing tags
function bindEditTagsAjax() {
  var manageTagsModal = null;
  var manageTagsModalBody = null;

  // Initialize reloading of manage tags modal content after posting new
  // tag.
  function initAddTagForm() {
    manageTagsModalBody.find(".add-tag-form")
      .on("ajax:success", function (e, data) {
        initTagsModalBody(data);
      });
  }

  // Initialize edit tag & remove tag functionality from my_module links.
  function initTagRowLinks() {
    manageTagsModalBody.find(".edit-tag-link")
      .on("click", function (e) {
        var $this = $(this);
        var li = $this.parents("li.list-group-item");
        var editDiv = $(li.find("div.tag-edit"));

        // Revert all rows to their original states
        manageTagsModalBody.find("li.list-group-item").each(function(){
          var li = $(this);
          li.css("background-color", li.data("color"));
          li.find(".edit-tag-form").clearFormErrors();
          li.find("input[type=text]").val(li.data("name"));
        });

        // Hide all other edit divs, show all show divs
        manageTagsModalBody.find("div.tag-edit").hide();
        manageTagsModalBody.find("div.tag-show").show();

        editDiv.find("input[type=text]").val(li.data("name"));
        editDiv.find('.edit-tag-color').colorselector('setColor', li.data("color"));

        li.find("div.tag-show").hide();
        editDiv.show();
      });
    manageTagsModalBody.find("div.tag-edit .dropdown-colorselector > .dropdown-menu li a")
      .on("click", function (e) {
        // Change background of the <li>
        var $this = $(this);
        var li = $this.parents("li.list-group-item");
        li.css("background-color", $this.data("value"));
      });
    manageTagsModalBody.find(".remove-tag-link")
      .on("ajax:success", function (e, data) {
        initTagsModalBody(data);
      });
      manageTagsModalBody.find(".delete-tag-form")
      .on("ajax:success", function (e, data) {
        initTagsModalBody(data);
      });
    manageTagsModalBody.find(".edit-tag-form")
      .on("ajax:success", function (e, data) {
        initTagsModalBody(data);
      })
      .on("ajax:error", function (e, data) {
        $(this).renderFormErrors("tag", data.responseJSON);
      });
    manageTagsModalBody.find(".cancel-tag-link")
      .on("click", function (e, data) {
        var $this = $(this);
        var li = $this.parents("li.list-group-item");

        li.css("background-color", li.data("color"));
        li.find(".edit-tag-form").clearFormErrors();

        li.find("div.tag-edit").hide();
        li.find("div.tag-show").show();
      });
  }

  // Initialize ajax listeners and elements style on modal body. This
  // function must be called when modal body is changed.
  function initTagsModalBody(data) {
    manageTagsModalBody.html(data.html);
    manageTagsModalBody.find(".selectpicker").selectpicker();
    initAddTagForm();
    initTagRowLinks();
  }

  manageTagsModal = $("#manage-module-tags-modal");
  manageTagsModalBody = manageTagsModal.find(".modal-body");

  // Reload tags HTML element when modal is closed
  manageTagsModal.on("hide.bs.modal", function () {
    var tagsEl = $("#module-tags");

    // Load HTML
    $.ajax({
      url: tagsEl.attr("data-module-tags-url"),
      type: "GET",
      dataType: "json",
      success: function (data) {
        tagsEl.find(".tags-refresh").html(data.html_module_header);
      },
      error: function (data) {
        // TODO
      }
    });
  });

  // Remove modal content when modal window is closed.
  manageTagsModal.on("hidden.bs.modal", function () {
    manageTagsModalBody.html("");
  });

  // initialize my_module tab remote loading
  $("a.edit-tags-link")
  .on("ajax:before", function () {
    manageTagsModal.modal('show');
  })
  .on("ajax:success", function (e, data) {
    $("#manage-module-tags-modal-module").text(data.my_module.name);
    initTagsModalBody(data);
  });
}

// Sets callback for completing/uncompleting task
function applyTaskCompletedCallBack() {
  $("[data-action='complete-task'], [data-action='uncomplete-task']")
    .on('click', function() {
      var button = $(this);
      $.ajax({
        url: button.data('link-url'),
        type: 'POST',
        dataType: 'json',
        success: function(data) {
          if (data.completed === true) {
            button.attr('data-action', 'uncomplete-task');
            button.find('.btn')
              .removeClass('btn-primary').addClass('btn-default');
          } else {
            button.attr('data-action', 'complete-task');
            button.find('.btn')
              .removeClass('btn-default').addClass('btn-primary');
          }
          $('.task-due-date').html(data.module_header_due_date_label);
          $('.task-state-label').html(data.module_state_label);
          button.find('button').replaceWith(data.new_btn);
        },
        error: function() {
        }
      });
    });
}

applyTaskCompletedCallBack();
bindEditDueDateAjax();
bindEditDescriptionAjax();
bindEditTagsAjax();

//= require protocols/import_export/eln_table.js
//= require jszip.min.js

function importProtocolFromFile(
    fileHandle,
    importUrl,
    params,
    importIntoProtocol,
    afterImportCallback
  ) {
  /*********************************************/
  /* GLOBAL VARIABLES                          */
  /*********************************************/
  var importModal = $("#import-protocol-modal");
  var xml = "";
  var protocolFolders = [];
  var protocolXmls = [];
  var zipFiles = "";
  var nrOfProtocols = 0;
  var currentProtocol = 0;

  /*********************************************/
  /* INNER FUNCTIONS                           */
  /*********************************************/
  function readEnvelope(envelope) {
    // Reset variables
    protocolFolders = [];
    protocolXmls = [];
    currentProtocol = 0;

    // Iterate through protocols in the envelope
    $(envelope).find("protocol").each(function() {
      var folder = $(this).attr("guid") + "/";
      protocolFolders.push(folder);

      var zxml = zipFiles.files[folder + "eln.xml"].asText();
      protocolXmls.push(zxml);
    });

    nrOfProtocols = protocolFolders.length;
  }

  function stepComparator(a, b) {
    return (parseInt($(a).attr("position")) - parseInt($(b).attr("position")));
  }

  function getAssetBytes(folder, stepGuid, fileRef) {
    var filePath = folder + stepGuid + "/" + fileRef;
    var assetBytes = zipFiles.files[filePath].asBinary();
    return window.btoa(assetBytes);
  }

  /* Template functions */

  function newPreviewElement(name, values) {
    var template = $("[data-template='" + name + "']").clone();
    template.removeAttr("data-template");
    template.show();

    // Populate values in the template
    if (values !== null) {
      _.each(values, function(val, key) {
        template.find("[data-val='" + key + "']").append(val);
      });
    }

    return template;
  }

  function addChildToPreviewElement(parentEl, name, childEl) {
    parentEl.find("[data-hold='" + name + "']").append(childEl);
  }

  function hidePartOfElement(element, name) {
    element.find("[data-toggle='" + name + "']").hide();
  }

  function newAssetElement(folder, stepGuid, fileRef, fileName, fileType) {
    var html = "<li>";
    if ($.inArray(fileType, ["image/png","image/jpeg","image/gif","image/bmp"]) > 0) {
      var assetBytes = getAssetBytes(folder, stepGuid, fileRef);

      html += "<img style='max-width:300px; max-height:300px;' src='data:" + fileType + ";base64," + assetBytes + "' />";
      html += "<br>";
    }
    html += "<span>" + fileName + "</span>";
    html += "</li>";
    return $.parseHTML(html);
  }

  /* Preview protocol */

  function previewProtocol(position, replaceVals) {
    // Update the title position in GUI (if neccesary)
    var titlePositionSuffix = $("[data-role='title-position']");
    if (nrOfProtocols > 1) {
      titlePositionSuffix.text(
        I18n.t(
          "protocols.import_export.import_modal.preview_title_position",
          { current: position + 1, total: nrOfProtocols }
        )
      );
      titlePositionSuffix.css("display", "inline");
      titlePositionSuffix.show();
    }
    else {
      titlePositionSuffix.text("");
      titlePositionSuffix.hide();
    }

    // Update general protocol info fields
    $(protocolXmls[position]).find("protocol").each(function() {
      if (replaceVals) {
        $("#import_protocol_name").val($(this).children("name").text());
        $("#protocol_authors").val($(this).children("authors").text());
        $("#import_protocol_description").val($(this).children("description").text());
      }
      $("#protocol_created_at").val($(this).children("created_at").text());
      $("#protocol_updated_at").val($(this).children("updated_at").text());
    });

    // PREVIEW

    // Sort steps
    var steps = $(protocolXmls[position]).find("protocol > steps > step");
    steps.sort(stepComparator);

    var previewContainer = $("[data-role='preview-container']");
    previewContainer.html("");

    // Iterate through steps
    steps.each(function(i, nodeEl) {
      var node = $(nodeEl);
      var stepGuid = node.attr("guid");
      var stepPosition = String(Number.parseInt(node.attr("position")) + 1);
      var stepName = node.children("name").text();
      var stepDescription = displayTinyMceAssetInDescription(
                              node,
                              protocolFolders[position],
                              stepGuid
                            );
      // Generate step element
      var stepEl = newPreviewElement(
        "step",
        {
          position: stepPosition,
          name: stepName,
          description: stepDescription
        }
      );

      // Iterate through step assets
      var assetNodes = node.find("assets > asset");
      if (assetNodes.length > 0) {
        assetNodes.each(function() {
          var fileRef = $(this).attr("fileRef");
          var fileName = $(this).children("fileName").text();
          var fileType = $(this).children("fileType").text();

          var assetEl = newAssetElement(
            protocolFolders[position],
            stepGuid,
            fileRef,
            fileName,
            fileType);

          // Append asset element to step
          addChildToPreviewElement(stepEl, "assets", assetEl);
        });
      } else {
        hidePartOfElement(stepEl, "assets");
      }

      // Iterate through step tables
      var tableNodes = node.find("elnTables > elnTable");
      if (tableNodes.length > 0) {
        tableNodes.each(function() {
          var tableId = $(this).attr("id");
          var tableName = $(this).children("name").text();
          var tableContent = $(this).children("contents").text();

          // Generate table element
          var tableEl = newPreviewElement(
            "table",
            { name: tableName }
          );
          var elnTableEl = generateElnTable(tableId, tableContent);
          addChildToPreviewElement(tableEl, "table", elnTableEl);

          // Now, append table element to step
          addChildToPreviewElement(stepEl, "tables", tableEl);
        });
      } else {
        hidePartOfElement(stepEl, "tables");
      }

      // Iterate through step checklists
      var checklistNodes = node.find("checklists > checklist");
      if (checklistNodes.length > 0) {
        checklistNodes.each(function() {
          var checklistId = $(this).attr("id");
          var checklistName = $(this).children("name").text();

          var checklistEl = newPreviewElement(
            "checklist",
            { name: checklistName }
          );

          // Iterate through checklist items
          $(this).find("items > item").each(function() {
            var itemId = $(this).attr("id");
            var itemText = $(this).children("text").text();

            var itemEl = newPreviewElement(
              "checklist-item",
              { text: itemText }
            );
            addChildToPreviewElement(checklistEl, "checklist-items", itemEl);
          });

          // Now, add checklist item to step
          addChildToPreviewElement(stepEl, "checklists", checklistEl);
        });
      }

      // Append step element to preview container
      previewContainer.append(stepEl);
    });
  }

  // display tiny_mce_assets in step description
  function displayTinyMceAssetInDescription(node, folder, stepGuid) {
    if (node.children('descriptionAssets').length === 0) {
      var description = node.children('description').html();
      return $('<div></div>').html(
        description.replace(/\[~tiny_mce_id:([0-9a-zA-Z]+)\]/,
                                   '<strong>Can\'t import image</strong>')
                   .replace('<!--[CDATA[  ', '')
                   .replace('  ]]--&gt;', '')
                   .replace('  ]]-->','')
                   .replace('  ]]&gt;', '')
      ).html();
    }
    var description = node.children('description').html();
    node.find('descriptionAssets > tinyMceAsset').each(function(i, element) {
      var match = '[~tiny_mce_id:' + element.getAttribute('tokenId') + ']';
      var assetBytes = getAssetBytes(folder,
                                     stepGuid,
                                     element.getAttribute('fileref'));
      var image_tag = "<img style='max-width:300px; max-height:300px;' src='data:" + element.children[1].innerHTML + ";base64," + assetBytes + "' />"
      description = description.replace(match, image_tag); // replace the token with image
    }).bind(this);
    // I know is crazy but is the only way I found to pass valid HTML
    return $('<div></div>').html(
      description.replace('<!--[CDATA[  ', '')
                 .replace('  ]]--&gt;', '')
                 .replace('  ]]-->','')
                 .replace('  ]]&gt;', '')
    ).html();
  }

  /* Navigation functions */

  function navigationJumpToFirstProtocol(ev) {
    ev.preventDefault();
    currentProtocol = 0;
    previewProtocol(currentProtocol, true);
    updateNavigationButtons();
  }

  function navigationJumpToPreviousProtocol(ev) {
    ev.preventDefault();
    if (currentProtocol > 0) {
      currentProtocol--;
    }
    previewProtocol(currentProtocol, true);
    updateNavigationButtons();
  }

  function navigationJumpToNextProtocol(ev) {
    ev.preventDefault();
    if (currentProtocol < (nrOfProtocols - 1)) {
      currentProtocol++;
    }
    previewProtocol(currentProtocol, true);
    updateNavigationButtons();
  }

  function navigationJumpToLastProtocol(ev) {
    ev.preventDefault();
    currentProtocol = nrOfProtocols - 1;
    previewProtocol(currentProtocol, true);
    updateNavigationButtons();
  }

  function updateNavigationButtons() {
    if (currentProtocol == 0) {
      $("[data-action='jump-to-first-protocol']").attr("disabled", "disabled");
      $("[data-action='jump-to-previous-protocol']").attr("disabled", "disabled");
    } else {
      $("[data-action='jump-to-first-protocol']").removeAttr("disabled");
      $("[data-action='jump-to-previous-protocol']").removeAttr("disabled");
    }
    if (currentProtocol == nrOfProtocols - 1) {
      $("[data-action='jump-to-next-protocol']").attr("disabled", "disabled");
      $("[data-action='jump-to-last-protocol']").attr("disabled", "disabled");
    } else {
      $("[data-action='jump-to-next-protocol']").removeAttr("disabled");
      $("[data-action='jump-to-last-protocol']").removeAttr("disabled");
    }
  }

  function prepareGui() {
    // Show/hide header & message
    var headerImport = importModal.find("[data-role='header-import']");
    var headerImportIntoProtocol = importModal.find("[data-role='header-import-into-protocol']");
    var importMessage = importModal.find("[data-role='import-message']");
    if (importIntoProtocol) {
      headerImport.hide();
      headerImportIntoProtocol.show();
      importMessage.show();
    } else {
      headerImport.show();
      headerImportIntoProtocol.hide();
      importMessage.hide();
    }
    // Show/hide appropriate buttons
    var multipleProtocolsButtons = importModal.find("[data-role='multiple-protocols-buttons']");
    var singleProtocolButtons = importModal.find("[data-role='single-protocol-buttons']");
    if (nrOfProtocols > 1) {
      multipleProtocolsButtons.show();
      singleProtocolButtons.hide();

      var importAllButtons = multipleProtocolsButtons.find("[data-role='import-all']");
      var importSingleButtons = multipleProtocolsButtons.find("[data-role='import-single']");
      if (importIntoProtocol) {
        importAllButtons.hide();
        importSingleButtons.show();
      } else {
        importAllButtons.show();
        importSingleButtons.hide();
      }
    } else {
      multipleProtocolsButtons.hide();
      singleProtocolButtons.show();
    }

    // Bind on "Import" buttons
    $("[data-action='import-current']")
    .off("click")
    .on("click", function(ev) { importCurrentProtocol(ev); });
    $("[data-action='import-all']")
    .off("click")
    .on("click", function(ev) { importAllProtocols(ev); });

    // Bind on navigation buttons
    $("[data-action='jump-to-first-protocol']")
    .off("click")
    .on("click", function(ev) { navigationJumpToFirstProtocol(ev); });
    $("[data-action='jump-to-previous-protocol']")
    .off("click")
    .on("click", function(ev) { navigationJumpToPreviousProtocol(ev); });
    $("[data-action='jump-to-next-protocol']")
    .off("click")
    .on("click", function(ev) { navigationJumpToNextProtocol(ev); });
    $("[data-action='jump-to-last-protocol']")
    .off("click")
    .on("click", function(ev) { navigationJumpToLastProtocol(ev); });
    updateNavigationButtons();
  }

  /* Actual import */

  function importCurrentProtocol(ev) {
    var check_linked = $("[data-role='protocol-status-bar']")
                        .text();
    var confirm_message = "";
    ev.preventDefault();
    if( check_linked.trim() !== '(unlinked)' ){
      confirm_message = I18n.t("protocols.import_export.import_modal.import_to_linked_task_file");
    } else {
      confirm_message = I18n.t("protocols.import_export.import_modal.import_into_protocol_confirm");
    }

    // Check for confirmation first
    if (importIntoProtocol && !confirm(confirm_message)) {
      importModal.modal("hide");
    } else {
      var path = new RegExp("modules");
      if( path.test( window.location.href ) ){
        animateSpinner();
        importSingleProtocol(currentProtocol, false, function(data) {
          importModal.find("[data-role='preview-container']").html("");
          afterImportCallback([data]);
        });

      } else {
        // Show spinner
        animateSpinner(importModal);
        importSingleProtocol(currentProtocol, false, function(data) {
            animateSpinner(importModal, false);
            importModal.find("[data-role='preview-container']").html("");
            importModal.modal("hide");
            afterImportCallback([data]);
        });
      }
    }
  }

  function importAllProtocols(ev) {
    var nrOfImportedProtocols = 0;
    var datas = [];

    ev.preventDefault();

    // Show spinner
    animateSpinner(importModal);

    nrOfImportedProtocols = 0;
    datas = [];

    // Use Deferred object to chain ajax requests
    var dfd = $.Deferred();
    dfd.resolve();

    for (var i = 0; i < nrOfProtocols; i++) {
      dfd = dfd.then(function() {
        importSingleProtocol(i, true, function(data) {
          nrOfImportedProtocols += 1;
          datas.push(data);

          if (nrOfImportedProtocols >= nrOfProtocols) {
            animateSpinner(importModal, false);
            importModal.find("[data-role='preview-container']").html("");
            importModal.modal("hide");
            afterImportCallback(datas);
          }
        });
      });
    }
  }

  function importSingleProtocol(index, replaceVals, resultCallback) {
    previewProtocol(index, replaceVals);

    // Retrieve general protocol info
    var name = $("#import_protocol_name").val();
    var desc = $("#import_protocol_description").val();
    var authors = $("#protocol_authors").val();
    var created_at = "";
    var updated_at = "";
    $(protocolXmls[index]).find("protocol").each(function() {
      created_at = $(this).find('created_at').text();
      updated_at = $(this).find('updated_at').text();
    });

    // Allright, let's construct the huge,
    // messy-pot of a protocol JSON
    var protocolJson = {};
    protocolJson.name = name;
    protocolJson.description = desc;
    protocolJson.authors = authors;
    protocolJson.created_at = created_at;
    protocolJson.updated_at = updated_at;

    var steps = $(protocolXmls[index]).find("protocol > steps > step");
    steps.sort(stepComparator);

    // Iterate through steps
    var stepsJson = [];
    steps.each(function() {
      var stepJson = {};
      var stepId = $(this).attr("id");
      var stepGuid = $(this).attr("guid");
      stepJson.id = stepId;
      stepJson.position = $(this).attr("position");
      stepJson.name = $(this).children("name").text();
      // I know is crazy but is the only way I found to pass valid HTML
      stepJson.description = $('<div></div>').html($(this)
                                             .children("description")
                                             .html()
                                             .replace('<!--[CDATA[', '')
                                             .replace(']]&gt;', ''))
                                             .html();
      // Iterage throug tiny_mce_assets
      var descriptionAssetsJson = [];
      $(this).find("descriptionAssets > tinyMceAsset").each(function() {
        var tinyMceAsset = {};
        var fileRef = $(this).attr("fileRef");
        tinyMceAsset.tokenId = $(this).attr('tokenId');
        tinyMceAsset.fileType= $(this).children("fileType").text();
        tinyMceAsset.bytes = getAssetBytes(
          protocolFolders[index],
          stepGuid,
          fileRef
        )
        descriptionAssetsJson.push(tinyMceAsset);
      });
      stepJson.descriptionAssets = descriptionAssetsJson;

      // Iterate through assets
      var stepAssetsJson = [];
      $(this).find("assets > asset").each(function(){
        var stepAssetJson = {};
        var assetId = $(this).attr("id");
        var fileRef = $(this).attr("fileRef");
        stepAssetJson.id = assetId;
        var fileName = $(this).children("fileName").text();
        stepAssetJson.fileName = fileName;
        stepAssetJson.fileType = $(this).children("fileType").text();
        stepAssetJson.bytes = getAssetBytes(
          protocolFolders[index],
          stepGuid,
          fileRef
        );

        stepAssetsJson.push(stepAssetJson);
      });
      stepJson.assets = stepAssetsJson;

      // Iterate through step tables
      var stepTablesJson = [];
      $(this).find("elnTables > elnTable").each(function(){
        var stepTableJson = {};
        stepTableJson.id = $(this).attr("id");
        stepTableJson.name = $(this).children("name").text();
        var contents = $(this).children("contents").text();
        contents = hex2a(contents);
        contents = window.btoa(contents);
        stepTableJson.contents = contents;

        stepTablesJson.push(stepTableJson);
      });
      stepJson.tables = stepTablesJson;

      // Iterate through checklists
      var stepChecklistsJson = [];
      $(this).find("checklists > checklist").each(function() {
        var stepChecklistJson = {};
        stepChecklistJson.id = $(this).attr("id");
        stepChecklistJson.name = $(this).children("name").text();

        // Iterate through checklist items
        var itemsJson = [];
        $(this).find("items > item").each(function() {
          var itemJson = {};
          itemJson.id = $(this).attr("id");
          itemJson.position = $(this).attr("position");
          itemJson.text = $(this).children("text").text();
          itemsJson.push(itemJson);
        });
        stepChecklistJson.items = itemsJson;

        stepChecklistsJson.push(stepChecklistJson);
      });
      stepJson.checklists = stepChecklistsJson;

      stepsJson.push(stepJson);
    });
    protocolJson.steps = stepsJson;

    var data_json = { protocol: protocolJson };
    $.extend(data_json, params);

    var rough_size = roughSizeOfObject(data_json);
    if (rough_size > ($(document.body).data('file-max-size-mb') * 1024 * 1024)) {
      // Call the callback function
      resultCallback({ name: protocolJson["name"], new_name: null, status: "size_too_large" });
      return;
    }

    // Do a POST onto the server
    $.ajax({
      type: "POST",
      url: importUrl,
      dataType: "json",
      data: data_json,
      success: function(data) {
        resultCallback(data);
      },
      error: function(ev) {
        resultCallback(ev.responseJSON);

        var path = new RegExp("modules");
        if( path.test( window.location.href ) ){
          animateSpinner(null, false);
        }
      }
    });
  }

  /*********************************************/
  /* ACTUAL FUNCTION CODE                      */
  /*********************************************/
  if (!fileHandle) {
    alert(I18n.t("protocols.import_export.load_file_error"));
    return;
  }

  var fileReader = new FileReader();
  fileReader.onload = function(e) {
    var zipContent = new JSZip(e.target.result);
    zipFiles = new JSZip();
    zipFiles.load(e.target.result);

    var envelope = zipFiles.files["scinote.xml"].asText();
    readEnvelope(envelope);

    prepareGui();
    if (nrOfProtocols > 0) {
      previewProtocol(currentProtocol, true);
      importModal.modal("show");
    } else {
      alert(I18n.t("protocols.import_export.load_file_error"));
    }
  };
  fileReader.readAsArrayBuffer(fileHandle);
}

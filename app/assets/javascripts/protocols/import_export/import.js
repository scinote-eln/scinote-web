/* eslint-disable no-unused-vars, lines-around-comment, no-undef, no-alert */
/* eslint-disable no-use-before-define, no-restricted-globals */
//= require protocols/import_export/eln_table.js
//= require jszip.min.js

function importProtocolFromFile(
  fileHandle,
  importUrl,
  params,
  importIntoProtocol,
  afterImportCallback
) {
  /** *******************************************/
  /* GLOBAL VARIABLES                          */
  /** *******************************************/
  var importModal = $('#import-protocol-modal');
  var xml = '';
  var protocolFolders = [];
  var protocolXmls = [];
  var zipFiles = '';
  var nrOfProtocols = 0;
  var currentProtocol = 0;
  var fileReader;
  var dataJson;
  var roughSize;

  /** *******************************************/
  /* INNER FUNCTIONS                           */
  /** *******************************************/
  function readEnvelope(envelope) {
    // Reset variables
    protocolFolders = [];
    protocolXmls = [];
    currentProtocol = 0;

    // Iterate through protocols in the envelope
    $(envelope).find('protocol').each(function() {
      var folder = $(this).attr('guid') + '/';
      var zxml = zipFiles.files[folder + 'eln.xml'].asText();
      protocolFolders.push(folder);
      protocolXmls.push(zxml);
    });

    nrOfProtocols = protocolFolders.length;
  }

  function stepComparator(a, b) {
    return (parseInt($(a).attr('position'), 10) - parseInt($(b).attr('position'), 10));
  }

  function getAssetBytes(folder, stepGuid, fileRef) {
    var stepPath = stepGuid ? stepGuid + '/' : '';
    var filePath = folder + stepPath + fileRef;
    var assetBytes = zipFiles.files[filePath].asBinary();
    return window.btoa(assetBytes);
  }

  /* Template functions */

  function newPreviewElement(name, values) {
    var template = $("[data-template='" + name + "']").clone();
    template.removeAttr('data-template');
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
    var html = '<li>';
    var assetBytes;
    if ($.inArray(fileType, ['image/png', 'image/jpeg', 'image/gif', 'image/bmp']) > 0) {
      assetBytes = getAssetBytes(folder, stepGuid, fileRef);

      html += '<img style="max-width:300px; max-height:300px;" src="data:' + fileType + ';base64,' + assetBytes + '" />';
      html += '<br>';
    }
    html += '<span>' + fileName + '</span>';
    html += '</li>';
    return $.parseHTML(html);
  }

  /* Preview protocol */

  function previewProtocol(position, replaceVals) {
    // Update the title position in GUI (if neccesary)
    var steps;
    var previewContainer;
    var titlePositionSuffix = $("[data-role='title-position']");
    if (nrOfProtocols > 1) {
      titlePositionSuffix.text(
        I18n.t(
          'protocols.import_export.import_modal.preview_title_position',
          { current: position + 1, total: nrOfProtocols }
        )
      );
      titlePositionSuffix.css('display', 'inline');
      titlePositionSuffix.show();
    } else {
      titlePositionSuffix.text('');
      titlePositionSuffix.hide();
    }

    // Update general protocol info fields
    $(protocolXmls[position]).find('protocol').each(function() {
      var protocolDescription = displayTinyMceAssetInDescription(
        $(this),
        protocolFolders[position]
      );
      if (replaceVals) {
        $('#import_protocol_name').val($(this).children('name').text());
        $('#protocol_authors').val($(this).children('authors').text());
        $('#import_protocol_description').html(protocolDescription);
      }

      $.ajax({
        url: '/helpers/to_user_date_format.json',
        type: 'GET',
        data: {
          timestamp: $(this).children('created_at').text(),
          ts_format: 'full'
        },
        dataType: 'json',
        async: false,
        success: function(data) {
          $('#protocol_created_at').val(data.ts);
        }
      });
      $.ajax({
        url: '/helpers/to_user_date_format.json',
        type: 'GET',
        data: {
          timestamp: $(this).children('updated_at').text(),
          ts_format: 'full'
        },
        dataType: 'json',
        async: false,
        success: function(data) {
          $('#protocol_updated_at').val(data.ts);
        }
      });
    });

    // PREVIEW

    // Sort steps
    steps = $(protocolXmls[position]).find('protocol > steps > step');
    steps.sort(stepComparator);

    previewContainer = $('[data-role="preview-container"]');
    previewContainer.html('');

    // Iterate through steps
    steps.each(function(i, nodeEl) {
      var node = $(nodeEl);
      var stepGuid = node.attr('guid');
      var stepPosition = String(Number.parseInt(node.attr('position'), 10) + 1);
      var stepName = node.children('name').text();
      var checklistNodes;
      var tableNodes;
      var stepDescription = displayTinyMceAssetInDescription(
        node,
        protocolFolders[position],
        stepGuid
      );
      // Generate step element
      var stepEl = newPreviewElement(
        'step',
        {
          position: stepPosition,
          name: stepName,
          description: stepDescription
        }
      );

      // Iterate through step assets
      var assetNodes = node.find('assets > asset');
      if (assetNodes.length > 0) {
        assetNodes.each(function() {
          var fileRef = $(this).attr('fileRef');
          var fileName = $(this).children('fileName').text();
          var fileType = $(this).children('fileType').text();

          var assetEl = newAssetElement(
            protocolFolders[position],
            stepGuid,
            fileRef,
            fileName,
            fileType
          );

          // Append asset element to step
          addChildToPreviewElement(stepEl, 'assets', assetEl);
        });
      } else {
        hidePartOfElement(stepEl, 'assets');
      }

      // Iterate through step tables
      tableNodes = node.find('elnTables > elnTable');
      if (tableNodes.length > 0) {
        tableNodes.each(function() {
          var tableId = $(this).attr('id');
          var tableName = $(this).children('name').text();
          var tableContent = $(this).children('contents').text();

          // Generate table element
          var tableEl = newPreviewElement(
            'table',
            { name: tableName }
          );
          var elnTableEl = generateElnTable(tableId, tableContent);
          addChildToPreviewElement(tableEl, 'table', elnTableEl);

          // Now, append table element to step
          addChildToPreviewElement(stepEl, 'tables', tableEl);
        });
      } else {
        hidePartOfElement(stepEl, 'tables');
      }

      // Iterate through step checklists
      checklistNodes = node.find('checklists > checklist');
      if (checklistNodes.length > 0) {
        checklistNodes.each(function() {
          var checklistId = $(this).attr('id');
          var checklistName = $(this).children('name').text();

          var checklistEl = newPreviewElement(
            'checklist',
            { name: checklistName }
          );

          // Iterate through checklist items
          $(this).find('items > item').each(function() {
            var itemId = $(this).attr('id');
            var itemText = $(this).children('text').text();

            var itemEl = newPreviewElement(
              'checklist-item',
              { text: itemText }
            );
            addChildToPreviewElement(checklistEl, 'checklist-items', itemEl);
          });

          // Now, add checklist item to step
          addChildToPreviewElement(stepEl, 'checklists', checklistEl);
        });
      }

      // Append step element to preview container
      previewContainer.append(stepEl);
    });
  }

  // display tiny_mce_assets in step description
  function displayTinyMceAssetInDescription(node, folder, stepGuid) {
    var description;
    if (node.children('descriptionAssets').length === 0) {
      description = node.children('description').html();
      return $('<div></div>').html(
        description.replace(/\[~tiny_mce_id:([0-9a-zA-Z]+)\]/,
          '<strong>Can\'t import image</strong>')
          .replace('<!--[CDATA[  ', '')
          .replace('  ]]--&gt;', '')
          .replace('  ]]-->', '')
          .replace('  ]]&gt;', '')
      ).html();
    }
    description = node.children('description').html();
    description = description.replace('<!--[CDATA[  ', '')
      .replace('  ]]--&gt;', '')
      .replace('  ]]-->', '')
      .replace('  ]]&gt;', '');
    node.find('> descriptionAssets > tinyMceAsset').each(function(i, element) {
      var imageTag;
      var match = '[~tiny_mce_id:' + element.getAttribute('tokenId') + ']';
      var assetBytes = getAssetBytes(folder,
        stepGuid,
        element.getAttribute('fileref'));

      // new format load
      description = $('<div>' + description + '</div>');
      description.find('img[data-mce-token="' + element.getAttribute('tokenId') + '"]')
        .attr('src', 'data:' + element.children[1].innerHTML + ';base64,' + assetBytes);
      description = description.prop('outerHTML');

      // old format load
      imageTag = '<img style="max-width:300px; max-height:300px;" src="data:' + element.children[1].innerHTML + ';base64,' + assetBytes + '" />';
      description = description.replace(match, imageTag);
    });
    // I know is crazy but is the only way I found to pass valid HTML
    return $('<div></div>').html(description).html();
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
      currentProtocol -= 1;
    }
    previewProtocol(currentProtocol, true);
    updateNavigationButtons();
  }

  function navigationJumpToNextProtocol(ev) {
    ev.preventDefault();
    if (currentProtocol < (nrOfProtocols - 1)) {
      currentProtocol += 1;
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
    if (currentProtocol === 0) {
      $('[data-action="jump-to-first-protocol"]').attr('disabled', 'disabled');
      $('[data-action="jump-to-previous-protocol"]').attr('disabled', 'disabled');
    } else {
      $('[data-action="jump-to-first-protocol"]').removeAttr('disabled');
      $('[data-action="jump-to-previous-protocol"]').removeAttr('disabled');
    }
    if (currentProtocol === nrOfProtocols - 1) {
      $('[data-action="jump-to-next-protocol"]').attr('disabled', 'disabled');
      $('[data-action="jump-to-last-protocol"]').attr('disabled', 'disabled');
    } else {
      $('[data-action="jump-to-next-protocol"]').removeAttr('disabled');
      $('[data-action="jump-to-last-protocol"]').removeAttr('disabled');
    }
  }

  function prepareGui() {
    // Show/hide header & message
    var headerImport = importModal.find("[data-role='header-import']");
    var headerImportIntoProtocol = importModal.find("[data-role='header-import-into-protocol']");
    var importMessage = importModal.find("[data-role='import-message']");
    var importAllButtons;
    var importSingleButtons;
    var multipleProtocolsButtons;
    var singleProtocolButtons;

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
    multipleProtocolsButtons = importModal.find("[data-role='multiple-protocols-buttons']");
    singleProtocolButtons = importModal.find("[data-role='single-protocol-buttons']");
    if (nrOfProtocols > 1) {
      multipleProtocolsButtons.show();
      singleProtocolButtons.hide();

      importAllButtons = multipleProtocolsButtons.find("[data-role='import-all']");
      importSingleButtons = multipleProtocolsButtons.find("[data-role='import-single']");
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
    $('[data-action="import-current"]')
      .off('click')
      .on('click', function(ev) { importCurrentProtocol(ev); });
    $('[data-action="import-all"]')
      .off('click')
      .on('click', function(ev) { importAllProtocols(ev); });

    // Bind on navigation buttons
    $('[data-action="jump-to-first-protocol"]')
      .off('click')
      .on('click', function(ev) { navigationJumpToFirstProtocol(ev); });
    $('[data-action="jump-to-previous-protocol"]')
      .off('click')
      .on('click', function(ev) { navigationJumpToPreviousProtocol(ev); });
    $('[data-action="jump-to-next-protocol"]')
      .off('click')
      .on('click', function(ev) { navigationJumpToNextProtocol(ev); });
    $('[data-action="jump-to-last-protocol"]')
      .off('click')
      .on('click', function(ev) { navigationJumpToLastProtocol(ev); });
    updateNavigationButtons();
  }

  /* Actual import */

  function importCurrentProtocol(ev) {
    var checkLinked = $('[data-role="protocol-status-bar"]')
      .text();
    var confirmMessage = '';
    var path;
    ev.preventDefault();
    if (checkLinked.trim() !== '(unlinked)') {
      confirmMessage = I18n.t('protocols.import_export.import_modal.import_to_linked_task_file');
    } else {
      confirmMessage = I18n.t('protocols.import_export.import_modal.import_into_protocol_confirm');
    }

    // Check for confirmation first
    if (importIntoProtocol && !confirm(confirmMessage)) {
      importModal.modal('hide');
    } else {
      path = new RegExp('modules');
      if (path.test(window.location.href)) {
        animateSpinner();
        importSingleProtocol(currentProtocol, false, function(data) {
          importModal.find('[data-role="preview-container"]').html('');
          afterImportCallback([data]);
        });
      } else {
        // Show spinner
        animateSpinner(importModal);
        importSingleProtocol(currentProtocol, false, function(data) {
          animateSpinner(importModal, false);
          importModal.find('[data-role="preview-container"]').html('');
          importModal.modal('hide');
          afterImportCallback([data]);
        });
      }
    }
  }

  function importAllProtocols(ev) {
    var nrOfImportedProtocols = 0;
    var datas = [];
    var i;
    var dfd = $.Deferred();
    var dfdFunc = function(prt) {
      importSingleProtocol(prt, true, function(data) {
        nrOfImportedProtocols += 1;
        datas.push(data);
        if (nrOfImportedProtocols >= nrOfProtocols) {
          animateSpinner(importModal, false);
          importModal.find('[data-role="preview-container"]').html('');
          importModal.modal('hide');
          afterImportCallback(datas);
        }
      });
    };

    ev.preventDefault();

    // Show spinner
    animateSpinner(importModal);

    nrOfImportedProtocols = 0;
    datas = [];

    // Use Deferred object to chain ajax requests
    dfd.resolve();
    for (i = 0; i < nrOfProtocols; i += 1) {
      dfd = dfd.then(dfdFunc(i));
    }
  }


  function prepareTinyMceAssets(object, index, stepGuid) {
    var result = [];
    $(object).find('> descriptionAssets > tinyMceAsset').each(function() {
      var tinyMceAsset = {};
      var fileRef = $(this).attr('fileRef');
      tinyMceAsset.tokenId = $(this).attr('tokenId');
      tinyMceAsset.fileName = $(this).children('fileName').text();
      tinyMceAsset.fileType = $(this).children('fileType').text();
      if ($(this).children('fileMetadata').html() !== undefined) {
        tinyMceAsset.fileMetadata = $(this).children('fileMetadata').html()
          .replace('<!--[CDATA[', '')
          .replace('  ]]-->', '')
          .replace(']]&gt;', '');
      }
      tinyMceAsset.bytes = getAssetBytes(
        protocolFolders[index],
        stepGuid,
        fileRef
      );
      result.push(tinyMceAsset);
    });
    return result;
  }

  function importSingleProtocol(index, replaceVals, resultCallback) {
    // Retrieve general protocol info
    var name;
    var authors;
    var createdAt = '';
    var updatedAt = '';
    var descriptionAssetsJson = [];
    var protocolDescription;
    var protocolJson = {};
    var steps;
    var stepsJson = [];

    previewProtocol(index, replaceVals);

    name = $('#import_protocol_name').val();
    authors = $('#protocol_authors').val();
    steps = $(protocolXmls[index]).find('protocol > steps > step');

    $(protocolXmls[index]).find('protocol').each(function() {
      createdAt = $(this).find('created_at').text();
      updatedAt = $(this).find('updated_at').text();
      descriptionAssetsJson = prepareTinyMceAssets(this, index);
      protocolDescription = $('<div></div>').html($(this)
        .children('description')
        .html()
        .replace('<!--[CDATA[', '')
        .replace('  ]]-->', '')
        .replace(']]&gt;', ''))
        .html();
    });

    // Allright, let's construct the huge,
    // messy-pot of a protocol JSON
    protocolJson.name = name;
    protocolJson.description = protocolDescription;
    protocolJson.authors = authors;
    protocolJson.created_at = createdAt;
    protocolJson.updated_at = updatedAt;
    protocolJson.descriptionAssets = descriptionAssetsJson;
    steps.sort(stepComparator);

    // Iterate through steps
    steps.each(function() {
      var stepJson = {};
      var stepAssetsJson = [];
      var stepId = $(this).attr('id');
      var stepGuid = $(this).attr('guid');
      var stepTablesJson = [];
      var stepChecklistsJson = [];
      stepJson.id = stepId;
      stepJson.position = $(this).attr('position');
      stepJson.name = $(this).children('name').text();
      // I know is crazy but is the only way I found to pass valid HTML
      stepJson.description = $('<div></div>').html($(this)
        .children('description')
        .html()
        .replace('<!--[CDATA[', '')
        .replace('  ]]-->', '')
        .replace(']]&gt;', ''))
        .html();
      // Iterage throug tiny_mce_assets
      stepJson.descriptionAssets = prepareTinyMceAssets(this, index, stepGuid);
      // Iterate through assets

      $(this).find('assets > asset').each(function() {
        var stepAssetJson = {};
        var assetId = $(this).attr('id');
        var fileRef = $(this).attr('fileRef');
        var fileName = $(this).children('fileName').text();
        stepAssetJson.id = assetId;
        stepAssetJson.fileName = fileName;
        stepAssetJson.fileType = $(this).children('fileType').text();
        if ($(this).children('fileMetadata').html() !== undefined) {
          stepAssetJson.fileMetadata = $(this).children('fileMetadata').html()
            .replace('<!--[CDATA[', '')
            .replace('  ]]-->', '')
            .replace(']]&gt;', '');
        }
        stepAssetJson.bytes = getAssetBytes(
          protocolFolders[index],
          stepGuid,
          fileRef
        );

        stepAssetsJson.push(stepAssetJson);
      });
      stepJson.assets = stepAssetsJson;

      // Iterate through step tables
      $(this).find('elnTables > elnTable').each(function() {
        var stepTableJson = {};
        var contents = $(this).children('contents').text();
        stepTableJson.id = $(this).attr('id');
        stepTableJson.name = $(this).children('name').text();
        contents = hex2a(contents);
        contents = window.btoa(contents);
        stepTableJson.contents = contents;

        stepTablesJson.push(stepTableJson);
      });
      stepJson.tables = stepTablesJson;

      // Iterate through checklists
      $(this).find('checklists > checklist').each(function() {
        var stepChecklistJson = {};
        var itemsJson = [];
        stepChecklistJson.id = $(this).attr('id');
        stepChecklistJson.name = $(this).children('name').text();

        // Iterate through checklist items
        $(this).find('items > item').each(function() {
          var itemJson = {};
          itemJson.id = $(this).attr('id');
          itemJson.position = $(this).attr('position');
          itemJson.text = $(this).children('text').text();
          itemsJson.push(itemJson);
        });
        stepChecklistJson.items = itemsJson;

        stepChecklistsJson.push(stepChecklistJson);
      });
      stepJson.checklists = stepChecklistsJson;

      stepsJson.push(stepJson);
    });
    protocolJson.steps = stepsJson;

    dataJson = { protocol: protocolJson };
    $.extend(dataJson, params);

    roughSize = roughSizeOfObject(dataJson);
    if (roughSize > (GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024)) {
      // Call the callback function
      resultCallback({ name: protocolJson.name, new_name: null, status: 'size_too_large' });
      return;
    }

    // Do a POST onto the server
    $.ajax({
      type: 'POST',
      url: importUrl,
      dataType: 'json',
      data: dataJson,
      success: function(data) {
        resultCallback(data);
      },
      error: function(ev) {
        var path = new RegExp('modules');
        resultCallback(ev.responseJSON);

        if (path.test(window.location.href)) {
          animateSpinner(null, false);
        }
      }
    });
  }

  /** *******************************************/
  /* ACTUAL FUNCTION CODE                      */
  /** *******************************************/
  if (!fileHandle) {
    alert(I18n.t('protocols.import_export.load_file_error'));
    return;
  }

  fileReader = new FileReader();
  fileReader.onload = function(e) {
    var zipContent = new JSZip(e.target.result);
    var envelope;
    zipFiles = new JSZip();
    zipFiles.load(e.target.result);

    envelope = zipFiles.files['scinote.xml'].asText();
    readEnvelope(envelope);

    prepareGui();
    if (nrOfProtocols > 0) {
      previewProtocol(currentProtocol, true);
      importModal.modal('show');
    } else {
      alert(I18n.t('protocols.import_export.load_file_error'));
    }
  };
  fileReader.readAsArrayBuffer(fileHandle);
}

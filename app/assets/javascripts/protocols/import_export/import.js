/* eslint-disable no-param-reassign */
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

  function cleanFilePath(filePath) {
    if (filePath.slice(-1) === '.') {
      filePath = filePath.substring(0, filePath.length - 1);
    }

    return filePath;
  }

  function getAssetBytes(folder, stepGuid, fileRef) {
    const stepPath = stepGuid ? stepGuid + '/' : '';
    const filePath = folder + stepPath + fileRef;
    const assetBytes = zipFiles.files[cleanFilePath(filePath)].asBinary();
    return window.btoa(assetBytes);
  }

  function getAssetPreview(folder, stepGuid, fileRef, fileName, fileType) {
    if ($.inArray(fileType, ['image/png', 'image/jpeg', 'image/gif', 'image/bmp']) > 0) {
      return {
        fileName: fileName,
        fileType: fileType,
        bytes: getAssetBytes(folder, stepGuid, fileRef)
      };
    } else {
      const stepPath = stepGuid ? folder + stepGuid + '/' : folder;
      let baseName;
      baseName = fileRef.split('.');
      baseName.pop();
      baseName.join('.');
      let previewFileRef = zipFiles.file(new RegExp(stepPath + 'previews/' + baseName));
      if (previewFileRef.length > 0) {
        const previewFileExt = previewFileRef[0].name.split('.').at(-1);
        let previewFileName = fileName.split('.');
        previewFileName.splice(-1, 1, previewFileExt);
        previewFileName.join('.');
        return {
          fileName: previewFileName,
          fileType: `image/${previewFileExt}`,
          bytes: window.btoa(previewFileRef[0].asBinary())
        };
      }
    }
    return null;
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

  function newAssetElement(folder, stepGuid, fileRef, fileName, fileType) {
    let html = '<li class="col-xs-12">';
    let assetPreview = getAssetPreview(folder, stepGuid, fileRef, fileName, fileType);

    if (assetPreview) {
      html += '<img style="max-width:300px; max-height:300px;" src="data:' + assetPreview.fileType + ';base64,' + assetPreview.bytes + '" />';
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
      var assetNodes;
      var fileHeader;
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

      // Iterate through step checklists
      checklistNodes = node.find('checklists > checklist');
      if (checklistNodes.length > 0) {
        checklistNodes.each(function() {
          addChecklistPreview(stepEl, this);
        });
      }

      // Iterate through step tables
      tableNodes = node.find('elnTables > elnTable');
      if (tableNodes.length > 0) {
        tableNodes.each(function() {
          addTablePreview(stepEl, this);
        });
      }

      // Parse step elements
      $(this).find('stepElements > stepElement').sort(stepComparator).each(function() {
        $element = $(this);
        switch ($(this).attr('type')) {
          case 'Checklist':
            addChecklistPreview(stepEl, $(this).find('checklist'));
            break;
          case 'StepTable':
            addTablePreview(stepEl, $(this).find('elnTable'));
            break;
          case 'StepText':
            addStepTextPreview(stepEl, $(this).find('stepText'), protocolFolders[position], stepGuid);
            break;
          default:
            // nothing to do
            break;
        }
      });

      // Iterate through step assets
      assetNodes = node.find('assets > asset');
      if (assetNodes.length > 0) {
        fileHeader = newPreviewElement('asset-file-name', null);

        stepEl.append(fileHeader);

        assetNodes.each(function() {
          var fileRef = $(this).attr('fileRef');
          var fileName = $(this).children('fileName').text();
          var fileType = $(this).children('fileType').text();
          var assetEl;

          assetEl = newAssetElement(
            protocolFolders[position],
            stepGuid,
            fileRef,
            fileName,
            fileType
          );

          // Append asset element to step
          stepEl.append(assetEl);
        });
      }

      // Append step element to preview container
      previewContainer.append(stepEl);
    });
  }

  function addTablePreview(stepEl, tableNode) {
    var tableName = $(tableNode).children('name').text();
    var tableContent = $(tableNode).children('contents').text();
    var metadata = $(tableNode).children('metadata').text();
    var tableMetadata = metadata ? JSON.parse(metadata) : {};

    // Generate table element
    var tableEl = newPreviewElement(
      'table',
      { name: tableName }
    );
    var elnTableEl = generateElnTable(tableContent, tableMetadata);
    tableEl.append(elnTableEl);

    // Now, append table element to step
    stepEl.append(tableEl);
  }

  function addChecklistPreview(stepEl, checklistNode) {
    var checklistId = $(checklistNode).attr('id');
    var checklistName = $(checklistNode).children('name').text();

    var checklistEl = newPreviewElement(
      'checklist',
      { name: checklistName }
    );

    // Iterate through checklist items
    $(checklistNode).find('items > item').each(function() {
      var itemId = $(this).attr('id');
      var itemText = $(this).children('text').text();

      var itemEl = newPreviewElement(
        'checklist-item',
        { text: itemText }
      );
      checklistEl.append(itemEl);
    });

    // Now, add checklist item to step
    stepEl.append(stepEl, checklistEl);
  }

  function addStepTextPreview(stepEl, stepTextNode, folder, stepGuid) {
    const itemName = $(stepTextNode).children('name').text();
    const itemText = displayTinyMceAssetInDescription(stepTextNode, folder, stepGuid);

    const textEl = newPreviewElement(
      'step-text',
      { name: itemName, text: itemText }
    );

    stepEl.append(textEl);
  }

  // display tiny_mce_assets in step description
  function displayTinyMceAssetInDescription(node, folder, stepGuid) {
    var description = node.children('description').html() || node.children('contents').html();

    if (!description) return '';

    if (node.children('descriptionAssets').length === 0) {
      return $('<div></div>').html(
        description.replace(/\[~tiny_mce_id:([0-9a-zA-Z]+)\]/,
          '<strong>Can\'t import image</strong>')
          .replace('<!--[CDATA[  ', '')
          .replace('  ]]--&gt;', '')
          .replace('  ]]-->', '')
          .replace('  ]]&gt;', '')
      ).html();
    }

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
      $('[data-action="jump-to-first-protocol"]').attr('disabled', false);
      $('[data-action="jump-to-previous-protocol"]').attr('disabled', false);
    }
    if (currentProtocol === nrOfProtocols - 1) {
      $('[data-action="jump-to-next-protocol"]').attr('disabled', 'disabled');
      $('[data-action="jump-to-last-protocol"]').attr('disabled', 'disabled');
    } else {
      $('[data-action="jump-to-next-protocol"]').attr('disabled', false);
      $('[data-action="jump-to-last-protocol"]').attr('disabled', false);
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

  function stepTextJson(stepTextNode, folderIndex, stepGuid) {
    var json = {};
    json.name = stepTextNode.children('name').text();
    json.contents = $('<div></div>').html(
      stepTextNode.children('contents')
        .html()
        .replace('<!--[CDATA[', '')
        .replace('  ]]-->', '')
        .replace(']]&gt;', '')
    ).html();

    json.descriptionAssets = prepareTinyMceAssets(stepTextNode, folderIndex, stepGuid);

    return json;
  }

  function stepTableJson(tableNode) {
    var json = {};
    var contents = tableNode.children('contents').text();
    json.id = tableNode.attr('id');
    json.name = tableNode.children('name').text();
    json.metadata = tableNode.children('metadata').text();
    contents = hex2a(contents);
    contents = window.btoa(contents);
    json.contents = contents;

    return json;
  }

  function checklistJson(checklistNode) {
    var json = {};
    var itemsJson = [];
    json.id = checklistNode.attr('id');
    json.name = checklistNode.children('name').text();

    // Iterate through checklist items
    checklistNode.find('items > item').each(function() {
      var itemJson = {};
      itemJson.id = $(this).attr('id');
      itemJson.position = $(this).attr('position');
      itemJson.text = $(this).children('text').text();
      itemsJson.push(itemJson);
    });
    json.items = itemsJson;

    return json;
  }

  function stepElementJson(stepElementNode, folderIndex, stepGuid) {
    var json = {
      type: stepElementNode.attr('type')
    };

    switch (json.type) {
      case 'Checklist':
        json.checklist = checklistJson(stepElementNode.find('checklist'));
        break;
      case 'StepTable':
        json.elnTable = stepTableJson(stepElementNode.find('elnTable'));
        break;
      case 'StepText':
        json.stepText = stepTextJson(stepElementNode.find('stepText'), folderIndex, stepGuid);
        break;
      default:
        // nothing to do
        break;
    }

    return json;
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
    protocolJson.elnVersion = $(protocolXmls[index]).attr('version');
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
      if ($(this).children('description').html()) {
        stepJson.description = $('<div></div>').html($(this)
          .children('description')
          .html()
          .replace('<!--[CDATA[', '')
          .replace('  ]]-->', '')
          .replace(']]&gt;', ''))
          .html();
      }
      // Iterate through tiny_mce_assets
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

        stepAssetJson.preview_image = getAssetPreview(
          protocolFolders[index],
          stepGuid,
          fileRef,
          fileName,
          null
        );

        stepAssetsJson.push(stepAssetJson);
      });
      stepJson.assets = stepAssetsJson;

      // Iterate through step tables
      $(this).find('elnTables > elnTable').each(function() {
        stepTablesJson.push(stepTableJson($(this)));
      });
      stepJson.tables = stepTablesJson;

      // Iterate through checklists
      $(this).find('checklists > checklist').each(function() {
        stepChecklistsJson.push(checklistJson($(this)));
      });
      stepJson.checklists = stepChecklistsJson;

      // Parse step elements
      stepJson.stepElements = [];

      $(this).find('stepElements > stepElement').sort(stepComparator).each(function() {
        stepJson.stepElements.push(stepElementJson($(this), index, stepGuid));
      });

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

(function() {
  $('#pio_submit_btn_id').on('click', function(e) {
    e.preventDefault();
    $('#protocols_io_form').submit();
  });
  $('#protocols_io_form').on('submit', function(e) {
    e.preventDefault();
    const form = document.querySelector('#protocols_io_form'); // Find the <form> element
    const formData = new FormData(form); // Wrap form contents
    $.ajax({
      url: 'protocols/protocolsio_import_create',
      type: 'POST',
      data: formData,
      contentType: false,
      processData: false
    });
  });
}());

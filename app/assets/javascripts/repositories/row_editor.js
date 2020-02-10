/*
  globals HelperModule animateSpinner SmartAnnotation AssetColumnHelper GLOBAL_CONSTANTS
*/
/* eslint-disable no-unused-vars */

var RepositoryDatatableRowEditor = (function() {
  const NAME_COLUMN_ID = 'row-name';
  const TABLE_ROW = '<tr></tr>';
  const TABLE_CELL = '<td></td>';
  const EDIT_FORM_CLASS_NAME = GLOBAL_CONSTANTS.REPOSITORY_ROW_EDITOR_FORM_CLASS_NAME;

  var TABLE;

  // Initialize SmartAnnotation
  function initSmartAnnotation($row) {
    $row.find('[data-object="repository_cell"]').each(function(el) {
      if (el.data('atwho')) {
        SmartAnnotation.init(el);
      }
    });
  }

  function validateAndSubmit($table) {
    let $form = $table.find(`.${EDIT_FORM_CLASS_NAME}`);
    let $row = $form.closest('tr');
    let valid = true;
    let directUrl = $table.data('direct-upload-url');
    let $files = $row.find('input[type=file]');
    $row.find('.has-error').removeClass('has-error').find('span').remove();

    // Validations here
    $row.find('input').each(function() {
      let dataType = $(this).data('type');
      if (!dataType) return;

      valid = $.fn.dataTable.render[dataType + 'Validator']($(this));
      if (!valid) return false;
    });

    if (!valid) return false;

    animateSpinner($table, true);
    // DirectUpload here
    let uploadPromise = AssetColumnHelper.uploadFiles($files, directUrl);

    // Submission here
    uploadPromise
      .then(function() {
        $form.submit();
        return false;
      }).catch((reason) => {
        alert(reason);
        return false;
      });

    return null;
  }

  function initAssetCellActions($row) {
    let fileInputs = $row.find('input[type=file]');
    let deleteButtons = $row.find('.file-upload-button>span.delete-action');

    fileInputs.on('change', function() {
      let $input = $(this);
      let $fileBtn = $input.next('.file-upload-button');
      let $label = $fileBtn.find('label');

      if ($input[0].files[0]) {
        $label.text($input[0].files[0].name);
        $fileBtn.removeClass('new-file');
      } else {
        $label.text('');
        $fileBtn.addClass('new-file');
      }
      $fileBtn.removeClass('error');
    });


    deleteButtons.on('click', function() {
      let $fileBtn = $(this).parent();
      let $input = $fileBtn.prev('input[type=file]');
      let $label = $fileBtn.find('label');

      $fileBtn.addClass('new-file');
      $label.text('');
      $input.val('');
      $fileBtn.removeClass('error');

      if (!$input.data('is-empty')) { // set hidden field for deletion only if original value has been set on rendering
        $input
          .prev('.file-hidden-field-container')
          .html(`<input type="hidden"
                     form="${$input.attr('form')}"
                     name="repository_cells[${$input.data('col-id')}]"
                     value=""/>`);
      }
    });
  }

  function initFormSubmitAction(table) {
    TABLE = table;
    let $table = $(TABLE.table().node());

    $table.on('ajax:success', `.${EDIT_FORM_CLASS_NAME}`, function(ev, data) {
      TABLE.ajax.reload(() => {
        animateSpinner(null, false);
        HelperModule.flashAlertMsg(data.flash, 'success');
        $('html, body').animate({scrollLeft: 0}, 300);
      });
    });

    $table.on('ajax:error', `.${EDIT_FORM_CLASS_NAME}`, function(ev, data) {
      animateSpinner(null, false);
      HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
    });
  }

  function addNewRow(table) {
    TABLE = table;

    let $row = $(TABLE_ROW);
    const formId = 'repositoryNewRowForm';
    let actionUrl = $(TABLE.table().node()).data('createRecord');
    let rowForm = $(`
      <td>
        <form id="${formId}"
              class="${EDIT_FORM_CLASS_NAME}"
              action="${actionUrl}"
              method="post"
              data-remote="true">
        </form>
      </td>
    `);

    // First two columns are always present and visible
    $row.append(rowForm);
    $row.addClass('editing');
    $row.append($(TABLE_CELL));

    $(TABLE.table().node()).find('tbody').prepend($row);

    table.columns().every(function() {
      let column = this;
      let $header = $(column.header());

      if (column.index() < 2) return;
      if (!column.visible()) return;

      let columnId = $header.attr('id');

      let $cell = $(TABLE_CELL).appendTo($row);

      if (columnId === NAME_COLUMN_ID) {
        $.fn.dataTable.render.newRowName(formId, $cell);
      } else {
        let dataType = $header.data('type');
        if (dataType) {
          $.fn.dataTable.render['new' + dataType](formId, columnId, $cell, $header);
        }
      }
    });

    initSmartAnnotation($row);
    initAssetCellActions($row);

    TABLE.columns.adjust();
  }

  function switchRowToEditMode(row) {
    let $row = $(row.node());
    let itemId = row.id();
    let formId = `repositoryRowForm${itemId}`;
    let requestUrl = $(TABLE.table().node()).data('current-uri');
    let rowForm = $(`
      <form id="${formId}"
            class="${EDIT_FORM_CLASS_NAME}"
            action="${row.data().recordUpdateUrl}"
            method="patch"
            data-remote="true"
            data-row-id="${itemId}">
        <input name="id" type="hidden" value="${itemId}" />
        <input name="request_url" type="hidden" value="${requestUrl}" />
      </form>
    `);

    $row.find('td').first().append(rowForm);
    $row.addClass('editing');

    TABLE.cells(row.index(), row.columns().eq(0)).every(function() {
      let $header = $(TABLE.columns(this.index().column).header());
      let columnId = $header.attr('id');
      let dataType = $header.data('type');
      let cell = this;

      if (!cell.column(cell.index().column).visible()) return true; // return if cell is not visible

      if (columnId === NAME_COLUMN_ID) {
        $.fn.dataTable.render.editRowName(formId, cell);
      } else if (dataType) {
        $.fn.dataTable.render['edit' + dataType](formId, columnId, cell, $header);
      }

      return true;
    });

    initSmartAnnotation($row);
    initAssetCellActions($row);

    TABLE.columns.adjust();
  }

  return Object.freeze({
    EDIT_FORM_CLASS_NAME: EDIT_FORM_CLASS_NAME,
    initFormSubmitAction: initFormSubmitAction,
    validateAndSubmit: validateAndSubmit,
    switchRowToEditMode: switchRowToEditMode,
    addNewRow: addNewRow
  });
}());

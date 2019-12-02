/*
  globals HelperModule animateSpinner SmartAnnotation
*/

var RepositoryDatatableRowEditor = (function() {
  const NAME_COLUMN_ID = 'row-name';
  const TABLE_ROW = '<tr></tr>';
  const TABLE_CELL = '<td></td>';

  var TABLE;

  // Initialize SmartAnnotation
  function initSmartAnnotation($row) {
    $row.find('[data-object="repository_cell"]').each(function(el) {
      if (el.data('atwho')) {
        SmartAnnotation.init(el);
      }
    });
  }

  function initFormSubmitAction(table) {
    TABLE = table;
    let $table = $(TABLE.table().node());

    $table.on('ajax:beforeSend', '.repository-row-edit-form', function() {
      let $row = $(this).closest('tr');
      let valid = true;

      $row.find('.has-error').removeClass('has-error').find('span').remove();

      $row.find('input').each(function() {
        let dataType = $(this).data('type');
        if (!dataType) return;

        valid = $.fn.dataTable.render[dataType + 'Validator']($(this));
      });
      if (!valid) return false;

      animateSpinner(null, true);
    });

    $table.on('ajax:success', '.repository-row-edit-form', function(ev, data) {
      TABLE.ajax.reload();
      HelperModule.flashAlertMsg(data.flash, 'success');
    });

    $table.on('ajax:error', '.repository-row-edit-form', function(ev, data) {
      HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
    });

    $table.on('ajax:complete', '.repository-row-edit-form', function() {
      animateSpinner(null, false);
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
              class="repository-row-edit-form"
              action="${actionUrl}"
              method="post"
              data-remote="true">
        </form>
      </td>
    `);

    // First two columns are always present and visible
    $row.append(rowForm);
    $row.append($(TABLE_CELL));

    table.columns().every(function() {
      let column = this;
      let $header = $(column.header());

      if (column.index() < 2) return;
      if (!column.visible()) return;

      let columnId = $header.attr('id');

      if (columnId === NAME_COLUMN_ID) {
        $row.append($(TABLE_CELL).html($.fn.dataTable.render.newRowName(formId)));
      } else {
        let dataType = $header.data('type');
        if (dataType) {
          $row.append($(TABLE_CELL).html($.fn.dataTable.render['new' + dataType](formId, columnId)));
        } else {
          $row.append($(TABLE_CELL));
        }
      }
    });

    $(TABLE.table().node()).find('tbody').prepend($row);

    initSmartAnnotation($row);

    TABLE.columns.adjust();
  }

  function switchRowToEditMode(row) {
    let $row = $(row.node());
    let itemId = row.id();
    let formId = `repositoryRowForm${itemId}`;
    let requestUrl = $(TABLE.table().node()).data('current-uri');
    let rowForm = $(`
      <form id="${formId}"
            class="repository-row-edit-form"
            action="${row.data().recordUpdateUrl}"
            method="patch"
            data-remote="true"
            data-row-id="${itemId}">
        <input name="id" type="hidden" value="${itemId}" />
        <input name="request_url" type="hidden" value="${requestUrl}" />
      </form>
    `);

    $row.find('td').first().append(rowForm);

    TABLE.cells(row.index(), row.columns().eq(0)).every(function() {
      let $header = $(TABLE.columns(this.index().column).header());
      let columnId = $header.attr('id');
      let dataType = $header.data('type');
      let cell = this;

      if (!cell.column(cell.index().column).visible()) return true; // return if cell is not visible

      if (columnId === NAME_COLUMN_ID) {
        $.fn.dataTable.render.editRowName(formId, cell);
      } else if (dataType) {
        $.fn.dataTable.render['edit' + dataType](formId, columnId, cell);
      }

      return true;
    });

    initSmartAnnotation($row);

    TABLE.columns.adjust();
  }

  return Object.freeze({
    initFormSubmitAction: initFormSubmitAction,
    switchRowToEditMode: switchRowToEditMode,
    addNewRow: addNewRow
  });
}());

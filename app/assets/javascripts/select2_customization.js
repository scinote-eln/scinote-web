
$.fn.extend({
  select2Multiple: function(config = {}) {
    // Adding ID to each block
    var templateSelection = (state) => {
      return $('<span class="select2-block-body" data-select-id="' + state.id + '">'
        + (config.customSelection !== undefined ? config.customSelection(state) : state.text)
      + '</span>');
    };
    var select2 = this.select2({
      closeOnSelect: false,
      multiple: true,
      ajax: config.ajax,
      templateSelection: templateSelection
    });
    // Add dynamic size
    select2.next().css('width', '100%');

    // unlimited size
    if (config.unlimitedSize) {
      this[0].dataset.unlimitedSize = true;
      select2.next().find('.select2-selection').css('max-height', 'none');
      select2.next().find('.select2-selection .select2-selection__rendered').css('width', '100%');
    }


    // select all check
    this[0].dataset.singleDisplay = config.singleDisplay || false;
    if (this[0].dataset.selectAll === 'true') {
      $.each($(this).find('option'), (index, e) => { e.selected = true; });
      this.trigger('change');
    }
    if (config.singleDisplay) {
      $(this).updateSingleName();
    }
    return select2
      // Adding select all button
      .on('select2:open', function() {
        var selectElement = this;
        $('.select2-selection').scrollTo(0);
        $('.select2_select_all').remove();
        if (selectElement.dataset.selectAllButton !== undefined) {
          $('<div class="select2_select_all btn btn-default"><strong>' + selectElement.dataset.selectAllButton + '</strong></div>').prependTo('.select2-dropdown').on('click', function() {
            var elementsToSelect = $.map($(selectElement).find('option'), e => e.value);
            if ($(selectElement).find('option:selected').length === elementsToSelect.length) elementsToSelect = [];
            $(selectElement).val(elementsToSelect).trigger('change');
            $(selectElement).select2('close');
            $(selectElement).select2('open');
          });
        }
      })
      // Prevent shake bug with multiple select
      .on('select2:open select2:close', function() {
        $('.select2-selection').scrollTo(0);

        /* if (
          ($(this).val() != null && $(this).val().length > 3) ||
          this.dataset.unlimitedSize !== 'true'
        ) {
          $(this).next().find('.select2-search__field')[0].disabled = true;
        } else {
          $(this).next().find('.select2-search__field')[0].disabled = false;
        } */
      })
      // Prevent opening window when deleteing selection
      .on('select2:unselect', function() {
        var resultWindow = $('.select2-container--open');
        if (resultWindow.length === 0) {
          $(this).select2('open');
        }
      })
      // Fxied scroll bug
      .on('select2:selecting select2:unselecting', function(e) {
        $(e.currentTarget).data('scrolltop', $('.select2-results__options').scrollTop());
        $('.select2-selection').scrollTo(0);
      })
      // Fxied scroll bug
      .on('select2:select select2:unselect change', function(e) {
        $('.select2-selection').scrollTo(0);
        $('.select2-results__options').scrollTop($(e.currentTarget).data('scrolltop'));
        if (this.dataset.singleDisplay === 'true') {
          $(this).updateSingleName();
        }
      });
  },
  select2MultipleClearAll: function() {
    $(this).val([]).trigger('change');
  },
  // Create from multiple blocks single one with counter
  updateSingleName: function() {
    var template = '';
    var selectElement = this;
    var selectedOptions = selectElement.next().find('.select2-selection__choice');
    var optionsCounter = selectedOptions.length;
    var allOptionsSelected = this.find('option').length === optionsCounter;
    var optionText = allOptionsSelected ? this[0].dataset.selectMultipleAllSelected : optionsCounter + ' ' + this[0].dataset.selectMultipleName;
    if (optionsCounter > 1) {
      selectedOptions.remove();
      template = '<li class="select2-selection__choice">'
                  + '<span class="select2-selection__choice__remove" role="presentation">×</span>'
                    + optionText
                + '</li>';
      $(template).prependTo(selectElement.next().find('.select2-selection__rendered')).find('.select2-selection__choice__remove')
        .click(function() { selectElement.select2MultipleClearAll(); });
    }
  }
});

/* global PerfectScrollbar activePSB PerfectSb */
/* eslint-disable no-unused-vars, no-use-before-define */

var dropdownSelector = (function() {
  // /////////////////////
  // Support functions //
  // ////////////////////

  // Change direction of dropdown depends of container position
  function updateDropdownDirection(selector, container) {
    var windowHeight = $(window).height();
    var containerPosition = container[0].getBoundingClientRect().top;
    var containerHeight = container[0].getBoundingClientRect().height;
    var containerWidth = container[0].getBoundingClientRect().width;
    var bottomSpace = windowHeight - containerPosition - containerHeight;
    if (bottomSpace < 280) {
      container.addClass('inverse');
      container.find('.dropdown-container').css('max-height', `${(containerPosition - 82)}px`)
        .css('margin-bottom', `${(containerPosition * -1)}px`)
        .css('width', `${containerWidth}px`);
    } else {
      container.removeClass('inverse');
      container.find('.dropdown-container').css('max-height', `${(bottomSpace - 32)}px`)
        .css('width', '');
    }
  }

  // Get data in JSON from field
  function getCurrentData(container) {
    return JSON.parse(container.find('.data-field').val());
  }

  // Save data to the field
  function updateCurrentData(container, data) {
    container.find('.data-field').val(JSON.stringify(data));
  }

  // Search filter for non-ajax data
  function filterOptions(container, options) {
    var searchQuery = container.find('.seacrh-field').val();
    if (searchQuery.length === 0) return options;
    return $.grep(options, (n) => {
      return n.label.toLowerCase().includes(searchQuery.toLowerCase());
    });
  }

  // Check if all options selected, for non ajax data
  function allOptionsSelected(selector, container) {
    return JSON.parse(container.find('.data-field').val()).length === selector.find('option').length && !(selector.data('ajax-url'));
  }

  // Update dropdown selection, based on save data
  function refreshDropdownSelection(selector, container) {
    container.find('.dropdown-option, .dropdown-group').removeClass('select');
    $.each(getCurrentData(container), function(i, selectedOption) {
      container.find(`.dropdown-option[data-value="${selectedOption.value}"][data-group="${selectedOption.group}"]`)
        .addClass('select');
    });
    if (selector.data('select-by-group')) {
      $.each(container.find('.dropdown-group'), function(gi, group) {
        if ($(group).find('.dropdown-option').length === $(group).find('.dropdown-option.select').length) {
          $(group).addClass('select');
        }
      });
    }
  }

  // //////////////////////
  // Private functions ///
  // /////////////////////

  // Initialization of dropdown
  function generateDropdown(selector, config = {}) {
    var selectElement = $(selector);
    var optionContainer;
    var ps;
    var dropdownContainer = selectElement.after('<div class="dropdown-selector-container"></div>').next();

    selectElement.data('config', config);

    $(`
      <div class="dropdown-container"></div>
      <div class="input-field">
        <input type="text" class="seacrh-field" placeholder="${selectElement.data('placeholder')}"></input>
      </div>
      <input type="hidden" class="data-field" value="[]">
      
    `).appendTo(dropdownContainer);

    if (selectElement.data('select-all-button')) {
      $(`<div class="dropdown-select-all btn">${selectElement.data('select-all-button')}</div>`)
        .appendTo(dropdownContainer.find('.dropdown-container'))
        .click(() => {
          if (allOptionsSelected(selectElement, dropdownContainer) || selectElement.data('ajax-url')) {
            dropdownContainer.find('.dropdown-group, .dropdown-option').removeClass('select');
          } else {
            dropdownContainer.find('.dropdown-group, .dropdown-option').addClass('select');
          }
          saveData(selectElement, dropdownContainer);
        });
    }
    dropdownContainer.find('.seacrh-field').keyup(() => {
      loadData(selectElement, dropdownContainer);
    }).click((e) =>{
      e.stopPropagation();
      if (dropdownContainer.hasClass('open')) {
        loadData(selectElement, dropdownContainer);
      } else {
        dropdownContainer.find('.input-field').click();
      }
    });

    ps = new PerfectScrollbar(dropdownContainer.find('.dropdown-container')[0]);
    activePSB.push(ps);

    optionContainer = dropdownContainer.find('.dropdown-container');

    dropdownContainer.find('.input-field').click(() => {
      $('.dropdown-selector-container').removeClass('active');
      dropdownContainer.addClass('active');
      $('.dropdown-selector-container:not(.active)').removeClass('open');

      optionContainer.scrollTo(0);
      dropdownContainer.toggleClass('open');
      if (dropdownContainer.hasClass('open')) {
        loadData(selectElement, dropdownContainer);
        updateDropdownDirection(selectElement, dropdownContainer);
      }
    });
    $(window).resize(function() {
      updateDropdownDirection(selectElement, dropdownContainer);
    });

    $(window).click(() => {
      dropdownContainer.removeClass('open');
    });
    dropdownContainer.click((e) => {
      e.stopPropagation();
    });

    selectElement.css('display', 'none');
    updateDropdownDirection(selectElement, dropdownContainer);
  }

  // Load data to dropdown list
  function loadData(selector, container, ajaxData = null) {
    var data;
    if (ajaxData) {
      data = ajaxData;
    } else {
      data = dataSource(selector, container);
    }
    // Draw option object
    function drawOption(option, group = null) {
      return $(`
        <div class="dropdown-option checkbox-icon"
          data-label="${option.label}"
          data-group="${group ? group.value : ''}"
          data-value="${option.value}">
          ${option.label}
        </div>"
      `);
    }

    // Draw group object
    function drawGroup(group) {
      return $(`
        <div class="dropdown-group">
          <div class="group-name checkbox-icon">${group.label}</div>
        </div>
      `);
    }

    // Click action for option object
    function clickOption() {
      $(this).toggleClass('select');
      saveData(selector, container);
    }

    container.find('.dropdown-group, .dropdown-option').remove();
    if (!data || !data.length) return;

    if (selector.data('select-by-group')) {
      $.each(data, function(gi, group) {
        var groupElement = drawGroup(group);
        $.each(group.options, function(oi, option) {
          var optionElement = drawOption(option, group);
          optionElement.click(clickOption);
          optionElement.appendTo(groupElement);
        });
        groupElement.find('.group-name').click(function() {
          var groupContainer = $(this).parent();
          if (groupContainer.toggleClass('select').hasClass('select')) {
            groupContainer.find('.dropdown-option').addClass('select');
          } else {
            groupContainer.find('.dropdown-option').removeClass('select');
          }
          saveData(selector, container);
        });
        groupElement.appendTo(container.find('.dropdown-container'));
      });
    } else {
      $.each(data, function(oi, option) {
        var optionElement = drawOption(option);
        optionElement.click(clickOption);
        optionElement.appendTo(container.find('.dropdown-container'));
      });
    }

    PerfectSb().update_all();
    refreshDropdownSelection(selector, container);
  }

  // Save data to local field
  function saveData(selector, container) {
    var selectArray = getCurrentData(container);

    function findOption(options, option) {
      return options.findIndex(x => (x.value === option.dataset.value
        && x.group === option.dataset.group));
    }

    container.find('.seacrh-field').val('');

    $.each(container.find('.dropdown-container .dropdown-option'), function(oi, option) {
      var alreadySelected;
      var toDelete;
      var newOption;
      if ($(option).hasClass('select')) {
        alreadySelected = findOption(selectArray, option);
        if (alreadySelected === -1) {
          newOption = {
            label: option.dataset.label,
            value: option.dataset.value,
            group: option.dataset.group
          };
          selectArray.push(newOption);
        }
      } else {
        toDelete = findOption(selectArray, option);
        if (toDelete >= 0) selectArray.splice(toDelete, 1);
      }
    });
    updateCurrentData(container, selectArray);
    updateTags(selector, container);
  }

  // Refresh tags in input field
  function updateTags(selector, container) {
    var selectedOptions = getCurrentData(container);
    var searchFieldValue = container.find('.seacrh-field');

    // Draw tag and assign event
    function drawTag(data) {
      var customLabel = selector.data('config').tagLabel;
      var tag = $(`<div class="ds-tags" >
                  <div class="tag-label"
                    data-ds-tag-group="${data.group}"
                    data-ds-tag-id=${data.value}>
                    ${customLabel ? customLabel(data) : data.label}
                  </div>
                  <i class="fas fa-times"></i>
                </div>`).insertBefore(container.find('.input-field .seacrh-field'));

      tag.click((e) => { e.stopPropagation(); });
      tag.find('.fa-times').click(function(e) {
        var tagLabel = $(this).prev();
        var toDelete;
        e.stopPropagation();
        tagLabel.addClass('closing');
        setTimeout(() => {
          if (selector.data('combine-tags')) {
            container.find('.data-field').val('[]');
            updateTags(selector, container);
          } else {
            selectedOptions = getCurrentData(container);
            toDelete = selectedOptions.findIndex(x => (String(x.value) === String(tagLabel.data('ds-tag-id'))
              && String(x.group) === String(tagLabel.data('ds-tag-group'))
            ));
            selectedOptions.splice(toDelete, 1);
            updateCurrentData(container, selectedOptions);
            updateTags(selector, container);
          }
        }, 150);
      });
    }

    container.find('.ds-tags').remove();
    if (selector.data('combine-tags')) {
      if (selectedOptions.length === 1) {
        drawTag({ label: selectedOptions[0].label, value: selectedOptions[0].value });
      } else if (allOptionsSelected(selector, container)) {
        drawTag({ label: selector.data('select-multiple-all-selected'), value: 0 });
      } else if (selectedOptions.length > 1) {
        drawTag({ label: `${selectedOptions.length} ${selector.data('select-multiple-name')}`, value: 0 });
      }
    } else {
      $.each(selectedOptions, (ti, tag) => {
        drawTag(tag);
      });
    }

    searchFieldValue.attr('placeholder',
      selectedOptions.length > 0 ? '' : selector.data('placeholder'));

    if (selectedOptions.length > 1 && !selector.data('combine-tags')) {
      container.find('.ds-tags').addClass('stretch');
    } else {
      container.find('.ds-tags').removeClass('stretch');
    }

    updateDropdownDirection(selector, container);
    refreshDropdownSelection(selector, container);
    if (selector.data('config').onChange) {
      selector.data('config').onChange();
    }
  }

  // Convert local data or ajax data to same format
  function dataSource(selector, container) {
    var result = [];
    var groups;
    var options;
    var defaultParams;
    var customParams;
    var ajaxParams;
    if (selector.data('ajax-url')) {
      defaultParams = { query: container.find('.seacrh-field').val() };
      customParams = selector.data('config').ajaxParams;
      ajaxParams = customParams ? customParams(defaultParams) : defaultParams;

      $.get(selector.data('ajax-url'), ajaxParams, (data) => {
        loadData(selector, container, data);
      });
    } else if (selector.data('select-by-group')) {
      groups = selector.find('optgroup');
      $.each(groups, (gi, group) => {
        var groupElement = { label: group.label, value: group.label, options: [] };
        var groupOptions = filterOptions(container, $(group).find('option'));
        $.each(groupOptions, function(oi, option) {
          groupElement.options.push({ label: option.innerHTML, value: option.value });
        });
        if (groupElement.options.length > 0) result.push(groupElement);
      });
    } else {
      options = filterOptions(container, selector.find('option'));
      $.each(options, function(oi, option) {
        result.push({ label: option.innerHTML, value: option.value });
      });
    }
    return result;
  }

  // ////////////////////
  // Public functions ///
  // ////////////////////

  return {
    // Dropdown initialization
    init: (selector, config) => {
      generateDropdown(selector, config);
    },
    // Update dropdown position
    update_dropdown_position: (selector) => {
      updateDropdownDirection($(selector), $(selector).next());
    },
    // Get only values
    getValues: (selector) => {
      return $.map(getCurrentData($(selector).next()), (v) => {
        return v.value;
      });
    },
    // Get all data
    getAllData: (selector) => {
      return getCurrentData($(selector).next());
    }
  };
}());

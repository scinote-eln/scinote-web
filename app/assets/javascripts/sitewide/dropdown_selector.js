/* global PerfectScrollbar activePSB PerfectSb I18n */
/* eslint-disable no-unused-vars, no-use-before-define */

/*

  Data options for SELECT:
    data-ajax-url // Url for GET ajax request
    data-select-by-group // Add groups to dropdown
    data-disable-placeholder // Placeholder for disabled fields
    data-placeholder // Search placeholder
    data-disable-on-load // Disable input after initialization
    data-select-all-button // Text for select all button
    data-combine-tags // Combine multiple tags to one (in simple mode gives you multiple select)
    data-select-multiple-all-selected // Text for combine tags, when all selected
    data-select-multiple-name // Text for combine tags, when select more than one tag
    data-view-mode // Run in view mode

  Initialization

  dropdownSelector.init('#select-element', config)

  config = {
    localFilter: function(data), // Filter non-AJAX data
    optionLabel: function(option), // Change option label
    optionClass: string, // Add class to option
    optionStyle: string, // Add style to option
    tagLabel: function(tag), // Change tag label (only for tags)
    tagClass: string, // Add class to tag (only for tags)
    tagStyle: string, // Add style to tag (only for tags)
    ajaxParams: function(params), // Customize params to AJAX request
    onOpen: function(), // Run action on open options container
    onClose: function(), // Run action on close options container
    onSelect: function(), // Run action after select
    onChange: function(), // Run action after change
    onUnSelect: function(), // Run action after unselect
    customDropdownIcon: function(), // Add custom dropdown icon
    inputTagMode: boolean, // Use as simple input tag field
    selectKeys: array, // array of keys id which use for fast select // default - [13]
    noEmptyOption: boolean, // use defaut select (only for single option select). default 'false'
    singleSelect: boolean, // disable multiple select. default 'false'
    selectAppearance: string, // 'tag' or 'simple'. Default 'tag'
    closeOnSelect: boolean, // Close dropdown after select
    disableSearch: boolean, // Disable search
    emptyOptionAjax: boolean, // Add empty option for ajax request
  }


*/
var dropdownSelector = (function() {
  // /////////////////////
  // Support functions //
  // ////////////////////

  // Change direction of dropdown depends of container position
  function updateDropdownDirection(selector, container) {
    var windowHeight = $(window).height();
    var containerPosition = container[0].getBoundingClientRect().top;
    var containerPositionLeft = container[0].getBoundingClientRect().left;
    var containerHeight = container[0].getBoundingClientRect().height;
    var containerWidth = container[0].getBoundingClientRect().width;
    var bottomSpace;
    var modalContainer = container.closest('.modal-dialog');
    var modalContainerBottom = 0;
    var maxHeight = 0;

    if (modalContainer.length) {
      windowHeight = modalContainer.height() + modalContainer[0].getBoundingClientRect().top;
      containerPositionLeft -= modalContainer[0].getBoundingClientRect().left;
      modalContainerBottom = modalContainer[0].getBoundingClientRect().bottom;
      maxHeight += modalContainerBottom;
    }

    bottomSpace = windowHeight - containerPosition - containerHeight;

    if ((modalContainerBottom + bottomSpace) < 280) {
      container.addClass('inverse');
      container.find('.dropdown-container').css('max-height', `${(containerPosition - 122 + maxHeight)}px`)
        .css('margin-bottom', `${(containerPosition * -1)}px`)
        .css('left', `${containerPositionLeft}px`)
        .css('width', `${containerWidth}px`);
    } else {
      container.removeClass('inverse');
      container.find('.dropdown-container').css('max-height', `${(bottomSpace - 32 + maxHeight)}px`)
        .css('width', `${containerWidth}px`)
        .css('left', `${containerPositionLeft}px`)
        .css('margin-top', `${(bottomSpace * -1)}px`);
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
  function filterOptions(selector, container, options) {
    var customFilter = selector.data('config').localFilter;
    var searchQuery = container.find('.search-field').val();

    var data = customFilter ? customFilter(options) : options;
    if (searchQuery.length === 0) return data;
    return $.grep(data, (n) => {
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
      container.find(`.dropdown-option[data-value="${selectedOption.value}"][data-group="${selectedOption.group || ''}"]`)
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

  function enableViewMode(selector, container) {
    container
      .addClass('view-mode disabled')
      .removeClass('open')
      .find('.search-field').prop('disabled', true);
  }

  function disableEnableDropdown(selector, container, mode) {
    var searchFieldValue = container.find('.search-field');
    if (mode) {
      updateCurrentData(container, []);
      updateTags(selector, container, { skipChange: true });
      searchFieldValue.attr('placeholder', selector.data('disable-placeholder') || '');
      container.addClass('disabled').removeClass('open')
        .find('.search-field').val('')
        .prop('disabled', true);
    } else {
      container.removeClass('disabled')
        .find('.search-field').prop('disabled', false);
      updateTags(selector, container, { skipChange: true });
    }
  }

  // Read option to JSON
  function convertOptionToJson(option) {
    if (option === undefined) {
      return { label: '', value: '', params: {} };
    }
    return {
      label: option.innerHTML,
      value: option.value,
      group: option.dataset.group || '',
      params: JSON.parse(option.dataset.params || '{}')
    };
  }

  // Ajax intial values, we will use default options //
  function ajaxInitialValues(selector, container) {
    var intialData = [];
    $(selector).find('option').each((i, option) => {
      intialData.push(convertOptionToJson(option));
    });
    updateCurrentData(container, intialData);
    updateTags(selector, container, { skipChange: true });
  }

  // Add selected option to value
  function addSelectedOption(selector, container) {
    setData(selector, [convertOptionToJson($(selector).find('option:selected')[0])], true);
  }

  // Prepare custom dropdown icon
  function prepareCustomDropdownIcon(config) {
    if (config.customDropdownIcon) {
      return config.customDropdownIcon();
    }
    if (config.inputTagMode) {
      return '';
    }
    return '<i class="fas fa-caret-down right-icon"></i><i class="fas fa-search right-icon"></i>';
  }

  // Set new data
  function setData(selector, data, skipSelect) {
    updateCurrentData(selector.next(), data);
    refreshDropdownSelection(selector, selector.next());
    updateTags(selector, selector.next(), { select: true, skipSelect: skipSelect });
  }


  // Delete specific value
  function deleteValue(selector, container, value, group = '', skipUnselect = false) {
    var selectedOptions = getCurrentData(container);
    var toDelete = selectedOptions.findIndex(x => (String(x.value) === String(value)
      && (String(x.group) === String(group) || !selector.data('select-by-group'))
    ));
    selectedOptions.splice(toDelete, 1);
    updateCurrentData(container, selectedOptions);
    updateTags(selector, container, { unselect: true, tagId: value, skipUnselect: skipUnselect });
  }

  // Function generate new tag
  function addNewTag(selector, container) {
    var searchField = container.find('.search-field');
    var selectArray = getCurrentData(container);
    var newTag = {
      label: searchField.val(),
      value: searchField.val()
    };
    $.each(selectArray, function() {
      if (this.value === newTag.value) searchField.val('');
    });

    if (searchField.val().length <= 1) return;
    selectArray.push(newTag);
    searchField.val('');

    updateCurrentData(container, selectArray);
    updateTags(selector, container, { select: true });
  }

  // intialization keyboard control
  function initKeyboardControl(container) {
    container.find('.search-field').keydown(function(e) {
      var dropdownContainer = container.find('.dropdown-container');
      var pressedKey = e.keyCode;
      var selectedOption = dropdownContainer.find('.highlight');

      if (selectedOption.length === 0 && (pressedKey === 38 || pressedKey === 40)) {
        dropdownContainer.find('.dropdown-option').first().addClass('highlight');
      }

      if (pressedKey === 38) {
        if (selectedOption.prev('.dropdown-option').length) {
          selectedOption.removeClass('highlight').prev().addClass('highlight');
        }
        if (selectedOption.prev('.delimiter').length) {
          selectedOption.removeClass('highlight').prev().prev().addClass('highlight');
        }
      } else if (pressedKey === 40) {
        if (selectedOption.next('.dropdown-option').length) {
          selectedOption.removeClass('highlight').next().addClass('highlight');
        }
        if (selectedOption.next('.delimiter').length) {
          selectedOption.removeClass('highlight').next().next().addClass('highlight');
        }
      }
    });
  }

  // //////////////////////
  // Private functions ///
  // /////////////////////

  // Initialization of dropdown
  function generateDropdown(selector, config = {}) {
    var selectElement = $(selector);
    var optionContainer;
    var perfectScroll;
    var dropdownContainer;

    if (selectElement.length === 0) return;

    // Check if element exist or already initialized
    if (selectElement.next().hasClass('dropdown-selector-container')) selectElement.next().remove();

    // Create initial container after select block
    dropdownContainer = selectElement.after('<div class="dropdown-selector-container"></div>').next();

    // Save config info to select element
    selectElement.data('config', config);

    // Draw main elements
    $(`
      <div class="dropdown-container"></div>
      <div class="input-field">
        <input type="text" class="search-field" data-options-selected=0 placeholder="${selectElement.data('placeholder') || ''}"></input>
        ${prepareCustomDropdownIcon(config)}
      </div>
      <input type="hidden" class="data-field" value="[]">

    `).appendTo(dropdownContainer);

    // If we setup Select All we draw it and add correspond logic
    if (selectElement.data('select-all-button')) {
      $(`<div class="dropdown-select-all btn">${selectElement.data('select-all-button')}</div>`)
        .appendTo(dropdownContainer.find('.dropdown-container'))
        .click(() => {
          // For AJAX dropdown we will use only "Deselect All"
          if (allOptionsSelected(selectElement, dropdownContainer) || selectElement.data('ajax-url')) {
            dropdownContainer.find('.dropdown-group, .dropdown-option').removeClass('select');
          } else {
            dropdownContainer.find('.dropdown-group, .dropdown-option').addClass('select');
          }
          saveData(selectElement, dropdownContainer);
        });
    }


    if (selectElement.data('ajax-url') || config.inputTagMode) {
      // If we use AJAX dropdown or tags input, options become initial values
      ajaxInitialValues(selectElement, dropdownContainer);
    }


    // When we start typing it will dynamically update data
    dropdownContainer.find('.search-field')
      .keyup((e) => {
        if (e.keyCode === 38
          || e.keyCode === 40
          || (config.selectKeys || []).includes(e.keyCode)) {
          return;
        }
        e.stopPropagation();
        loadData(selectElement, dropdownContainer);
      })
      .keypress((e) => {
        if ((config.selectKeys || [13]).includes(e.keyCode)) {
          if (config.inputTagMode) {
            addNewTag(selectElement, dropdownContainer);
          } else if (dropdownContainer.find('.highlight').length) {
            dropdownContainer.find('.highlight').click();
          } else {
            dropdownContainer.find('.dropdown-option').first().click();
          }
          dropdownContainer.find('.search-field').val('');
        }
      }).click((e) =>{
        e.stopPropagation();
        if (dropdownContainer.hasClass('open')) {
          loadData(selectElement, dropdownContainer);
        } else {
          dropdownContainer.find('.input-field').click();
        }
      });

    // Initialize scroll bar inside options container
    perfectScroll = new PerfectScrollbar(dropdownContainer.find('.dropdown-container')[0]);
    activePSB.push(perfectScroll);

    // Select options container
    optionContainer = dropdownContainer.find('.dropdown-container');

    // Add click event to input field
    dropdownContainer.find('.input-field').click(() => {
      // Now we can have only one dropdown opened at same time
      $('.dropdown-selector-container').removeClass('active');
      dropdownContainer.addClass('active');
      $('.dropdown-selector-container:not(.active)').removeClass('open');

      // If dropdown disabled or we use it in tag mode we not open it
      if (dropdownContainer.hasClass('disabled') || config.inputTagMode) return;

      // Each time we open option contianer we must scroll it
      optionContainer.scrollTo(0);

      // Now open/close option container
      dropdownContainer.toggleClass('open');
      if (dropdownContainer.hasClass('open')) {
        // on Open we load new data
        loadData(selectElement, dropdownContainer);
        updateDropdownDirection(selectElement, dropdownContainer);
        dropdownContainer.find('.search-field').focus();

        // onOpen event
        if (config.onOpen) {
          config.onOpen();
        }
      } else {
        // on Close we blur search field
        dropdownContainer.find('.search-field').blur();

        // onClose event
        if (config.onClose) {
          config.onClose();
        }
      }
    });

    // When user will resize browser we must check dropdown position
    $(window).resize(() => { updateDropdownDirection(selectElement, dropdownContainer); });
    $(window).scroll(() => { updateDropdownDirection(selectElement, dropdownContainer); });

    // When user will click away, we must close dropdown
    $(window).click(() => {
      if (dropdownContainer.hasClass('open')) {
        dropdownContainer.find('.search-field').val('');
      }
      if (dropdownContainer.hasClass('open') && config.onClose) {
        config.onClose();
      }
      dropdownContainer.removeClass('open active');
    });

    // Prevent closing dropdown if we click inside
    dropdownContainer.click((e) => { e.stopPropagation(); });

    // Hide original select element
    selectElement.css('display', 'none');


    // Disable dropdown by default
    if (selectElement.data('disable-on-load')) disableEnableDropdown(selectElement, dropdownContainer, true);

    // EnableView mode
    if (selectElement.data('view-mode')) {
      enableViewMode(selectElement, dropdownContainer);
    }

    // Select default value
    if (config.noEmptyOption && config.singleSelect) {
      addSelectedOption(selectElement, dropdownContainer);
    }

    // Enable simple mode for dropdown selector
    if (config.selectAppearance === 'simple') {
      dropdownContainer.addClass('simple-mode');
      if (dropdownContainer.find('.tag-label').length) {
        dropdownContainer.find('.search-field').attr('placeholder', dropdownContainer.find('.tag-label').text().trim());
      }
    }

    // Disable search
    if (config.disableSearch) {
      dropdownContainer.addClass('disable-search');
    }

    // initialization keyboard controll
    initKeyboardControl(dropdownContainer);

    // In some case dropdown position not correclty calculated
    updateDropdownDirection(selectElement, dropdownContainer);
  }

  // Load data to dropdown list
  function loadData(selector, container, ajaxData = null) {
    var data;
    var containerDropdown = container.find('.dropdown-container');
    // We need to remeber previos option container size before update
    containerDropdown.css('height', `${containerDropdown.height()}px`);
    if (ajaxData) {
      // For ajax we simpy use data from request
      data = ajaxData;
    } else {
      // For local from select options
      data = dataSource(selector, container);
    }

    // Draw option object
    function drawOption(selector2, option, group = null) {
      // Check additional params from config
      var customLabel = selector2.data('config').optionLabel;
      var customClass = selector2.data('config').optionClass || '';
      var customStyle = selector2.data('config').optionStyle;
      return $(`
        <div class="dropdown-option ${customClass}" style="${customStyle ? customStyle(option) : ''}"
          data-params='${JSON.stringify(option.params || {})}'
          data-label="${option.label}"
          data-group="${group ? group.value : ''}"
          data-value="${option.value}">
            ${customLabel ? customLabel(option) : option.label}
        </div>"
      `);
    }

    // Draw delimiter object
    function drawDelimiter() {
      return $('<div class="delimiter"></div>');
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
      var $container = $(this).closest('.dropdown-selector-container');
      // Unselect all previous one if single select
      if (selector.data('config').singleSelect) {
        $container.find('.dropdown-option').removeClass('select');
        updateCurrentData($container, []);
        selector.val($(this).data('value')).change();
      }
      $(this).toggleClass('select');
      saveData(selector, $container);
    }

    // Remove placeholder from option container
    container.find('.dropdown-group, .dropdown-option, .empty-dropdown, .delimiter').remove();
    if (!data) return;

    if (data.length > 0) {
      // If we use select-by-group option we need first draw groups
      if (selector.data('select-by-group')) {
        $.each(data, function(gi, group) {
          // First we create our group
          var groupElement = drawGroup(group);
          // Now add options to this group
          $.each(group.options, function(oi, option) {
            var optionElement = drawOption(selector, option, group);
            optionElement.click(clickOption);
            optionElement.appendTo(groupElement);
          });

          // Now for each group we add action to select all options
          groupElement.find('.group-name').click(function() {
            var groupContainer = $(this).parent();

            // Disable group select to single select
            if (selector.data('config').singleSelect) return;

            if (groupContainer.toggleClass('select').hasClass('select')) {
              groupContainer.find('.dropdown-option').addClass('select');
            } else {
              groupContainer.find('.dropdown-option').removeClass('select');
            }
            saveData(selector, container);
          });

          // And finally appen group to option container
          groupElement.appendTo(container.find('.dropdown-container'));
        });
      } else {
        // For simple options we only draw them
        $.each(data, function(oi, option) {
          var optionElement;
          if (option.delimiter) {
            drawDelimiter().appendTo(container.find('.dropdown-container'));
            return;
          }
          optionElement = drawOption(selector, option);
          optionElement.click(clickOption);
          optionElement.appendTo(container.find('.dropdown-container'));
        });
      }
    } else {
      // If we data empty, draw placeholder
      $(`<div class="empty-dropdown">${I18n.t('dropdown_selector.nothing_found')}</div>`).appendTo(container.find('.dropdown-container'));
    }

    // Update scrollbar
    PerfectSb().update_all();

    // Check position of option dropdown
    refreshDropdownSelection(selector, container);

    // Unfreeze option container height
    containerDropdown.css('height', 'auto');
  }

  // Save data to local field
  function saveData(selector, container) {
    // Check what we have now selected
    var selectArray = getCurrentData(container);

    // Search option by value and group
    function findOption(options, option) {
      return options.findIndex(x => (x.value === option.dataset.value
        && x.group === option.dataset.group));
    }

    // First we clear search field
    if (selector.data('config').singleSelect) container.find('.search-field').val('');

    // Now we check all options in dropdown for selection and add them to array
    $.each(container.find('.dropdown-container .dropdown-option'), function(oi, option) {
      var alreadySelected;
      var toDelete;
      var newOption;
      if ($(option).hasClass('select')) {
        alreadySelected = findOption(selectArray, option);

        // If it is new option we add it
        if (alreadySelected === -1) {
          newOption = {
            label: option.dataset.label,
            value: option.dataset.value,
            group: option.dataset.group,
            params: JSON.parse(option.dataset.params)
          };
          selectArray.push(newOption);
        }
      } else {
        // If we deselect option we remove it
        toDelete = findOption(selectArray, option);
        if (toDelete >= 0) selectArray.splice(toDelete, 1);
      }
      // This complex required to save order of tags
    });
    // Now we save new data
    updateCurrentData(container, selectArray);
    // Redraw tags
    updateTags(selector, container, { select: true });
  }

  // Refresh tags in input field
  function updateTags(selector, container, config = {}) {
    var selectedOptions = getCurrentData(container);
    var searchFieldValue = container.find('.search-field');

    // Draw tag and assign event
    function drawTag(data) {
      // Check for custom options
      var customLabel = selector.data('config').tagLabel;
      var customClass = selector.data('config').tagClass || '';
      var customStyle = selector.data('config').tagStyle;

      // Select element appearance
      var tagAppearance = selector.data('config').selectAppearance === 'simple' ? 'ds-simple' : 'ds-tags';
      var label = customLabel ? customLabel(data) : data.label;
      // Add new tag before search field
      var tag = $(`<div class="${tagAppearance} ${customClass}" style="${customStyle ? customStyle(data) : ''}" >
                  <div class="tag-label"
                    title="${$('<span>' + label + '</span>').text()}"
                    data-ds-tag-group="${data.group}"
                    data-ds-tag-id="${data.value}">
                    ${label}
                  </div>
                  <i class="fas fa-times ${selector.data('config').singleSelect ? 'hidden' : ''}"></i>
                </div>`).insertBefore(container.find('.input-field .search-field'));

      // Now we need add delete action to tag
      tag.find('.fa-times').click(function(e) {
        var tagLabel = $(this).prev();
        var toDelete;
        e.stopPropagation();
        // Start delete animation
        $(this).parent().addClass('closing');
        // Add timeout for deleting animation
        setTimeout(() => {
          if (selector.data('combine-tags')) {
            // if we use combine-tags optons we simply clear all values
            container.find('.data-field').val('[]');
            updateTags(selector, container);
          } else {
            // Or delete specific one
            deleteValue(selector, container, tagLabel.data('ds-tag-id'), tagLabel.data('ds-tag-group'));
          }
        }, 350);
      });
    }

    // Clear all tags
    container.find('.ds-tags, .ds-simple').remove();
    if (selector.data('combine-tags')) {
      // If we use combine-tags options we draw only one tag
      if (selectedOptions.length === 1) {
        // If only one selected we use his name
        drawTag({ label: selectedOptions[0].label, value: selectedOptions[0].value });
      } else if (allOptionsSelected(selector, container)) {
        // If all selected we use placeholder for all tags from select config
        drawTag({ label: selector.data('select-multiple-all-selected'), value: 0 });
        // Otherwise use placeholder from select config
      } else if (selectedOptions.length > 1) {
        drawTag({ label: `${selectedOptions.length} ${selector.data('select-multiple-name')}`, value: 0 });
      }
    } else {
      // For normal tags we simpy draw each
      $.each(selectedOptions, (ti, tag) => {
        drawTag(tag);
      });
    }

    // If we have alteast one tag, we need to remove placeholder from search field
    if (selector.data('config').selectAppearance === 'simple') {
      let selectedLabel = container.find('.tag-label');
      container.find('.search-field').attr('placeholder',
        selectedLabel.length && selectedLabel.text().trim() !== '' ? selectedLabel.text().trim() : selector.data('placeholder'));
    } else {
      searchFieldValue.attr('placeholder',
        selectedOptions.length > 0 ? '' : (selector.data('placeholder') || ''));
    }

    searchFieldValue.attr('data-options-selected', selectedOptions.length);

    // Add stretch class for visual improvments
    if (!selector.data('combine-tags')) {
      container.find('.ds-tags').addClass('stretch');
    } else {
      container.find('.ds-tags').removeClass('stretch');
    }

    // Update option container direction position
    updateDropdownDirection(selector, container);
    // Update options selection status
    refreshDropdownSelection(selector, container);

    // If dropdown active focus on search field
    if (container.hasClass('open')) container.find('.search-field').focus();

    // Trigger onSelect event
    if (selector.data('config').onSelect && !config.skipChange && config.select && !config.skipSelect) {
      selector.data('config').onSelect();
    }

    // Trigger onChange event
    if (selector.data('config').onChange && !config.skipChange) {
      selector.data('config').onChange();
    }

    // Trigger onUnSelect event
    if (selector.data('config').onUnSelect && !config.skipChange && config.unselect && !config.skipUnselect) {
      selector.data('config').onUnSelect(config.tagId);
    }

    // Close dropdown after select
    if (selector.data('config').closeOnSelect && container.hasClass('open')) {
      container.find('.input-field').click();
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
    // If use AJAX we need to prepare correct format on backend
    if (selector.data('ajax-url')) {
      defaultParams = { query: container.find('.search-field').val() };
      customParams = selector.data('config').ajaxParams;
      ajaxParams = customParams ? customParams(defaultParams) : defaultParams;

      $.get(selector.data('ajax-url'), ajaxParams, (data) => {
        var optionsAjax = data;
        if (selector.data('config').emptyOptionAjax) {
          optionsAjax = [{
            label: '',
            value: '',
            group: null,
            params: {}
          }].concat(data);
        }
        loadData(selector, container, optionsAjax);
        PerfectSb().update_all();
      });
    // For local options we convert options element from select to correct array
    } else if (selector.data('select-by-group')) {
      groups = selector.find('optgroup');
      $.each(groups, (gi, group) => {
        var groupElement = { label: group.label, value: group.label, options: [] };
        var groupOptions = filterOptions(selector, container, $(group).find('option'));
        $.each(groupOptions, function(oi, option) {
          groupElement.options.push({ label: option.innerHTML, value: option.value });
        });
        if (groupElement.options.length > 0) result.push(groupElement);
      });
    } else {
      options = filterOptions(selector, container, selector.find('option'));
      $.each(options, function(oi, option) {
        result.push({
          label: option.innerHTML,
          value: option.value,
          delimiter: option.dataset.delimiter,
          params: JSON.parse(option.dataset.params || '{}')
        });
      });
    }
    return result;
  }

  // ////////////////////
  // Public functions ///
  // ////////////////////

  return {
    // Dropdown initialization
    init: function(selector, config) {
      generateDropdown(selector, config);

      return this;
    },

    // Clear button initialization
    initClearButton: function(selector, clearButton) {
      var container;

      if ($(selector).length === 0) return false;

      container = $(selector).next();
      $(clearButton).click(() => {
        updateCurrentData(container, []);
        refreshDropdownSelection($(selector), container);
        updateTags($(selector), container);
      });

      return this;
    },
    // Update dropdown position
    updateDropdownDirection: function(selector) {
      if ($(selector).length === 0) return false;

      if (!$(selector).next().hasClass('open')) return false;

      updateDropdownDirection($(selector), $(selector).next());

      return this;
    },
    // Get only values
    getValues: function(selector) {
      var values;
      if ($(selector).length === 0) return false;
      values = $.map(getCurrentData($(selector).next()), (v) => {
        return v.value;
      });
      if ($(selector).data('config').singleSelect) return values[0];

      return values;
    },
    // Get all data
    getData: function(selector) {
      if ($(selector).length === 0) return false;

      return getCurrentData($(selector).next());
    },

    // Set data to selector
    setData: function(selector, data) {
      if ($(selector).length === 0) return false;

      setData($(selector), []);

      return this;
    },

    // Clear selector
    clearData: function(selector) {
      if ($(selector).length === 0) return false;

      setData($(selector), []);
      return this;
    },

    removeValue: function(selector, value, group = '', skip_event = false) {
      var dropdownContainer;
      if ($(selector).length === 0) return false;
      dropdownContainer = $(selector).next();

      deleteValue($(selector), dropdownContainer, value, null, skip_event);
      return this;
    },

    addValue: function(selector, value, skip_event = false) {
      var currentData;
      if ($(selector).length === 0) return false;
      currentData = getCurrentData($(selector).next());
      currentData.push(value);
      setData($(selector), currentData, skip_event);

      return this;
    },

    // Enable selector
    enableSelector: function(selector) {
      if ($(selector).length === 0) return false;

      disableEnableDropdown($(selector), $(selector).next(), false);

      return this;
    },

    // Disable selector
    disableSelector: function(selector) {
      if ($(selector).length === 0) return false;

      disableEnableDropdown($(selector), $(selector).next(), true);

      return this;
    },

    // close dropdown
    closeDropdown: function(selector) {
      var dropdownContainer;

      if ($(selector).length === 0) return false;
      dropdownContainer = $(selector).next();
      if (dropdownContainer.hasClass('open')) {
        dropdownContainer.find('.input-field').click();
      }

      return this;
    },

    // get dropdown container
    getContainer: function(selector) {
      if ($(selector).length === 0) return false;
      return $(selector).next();
    },

    // Run success animation on dropdown
    highlightSuccess: function(selector) {
      var container = $(selector).next();
      if ($(selector).length === 0) return false;
      container.addClass('success');
      setTimeout(() => {
        container.removeClass('success');
      }, 1500);
      return this;
    },

    // Run error animation on dropdown
    highlightError: function(selector) {
      var container = $(selector).next();
      if ($(selector).length === 0) return false;
      container.addClass('error');
      setTimeout(() => {
        container.removeClass('error');
      }, 1500);
      return this;
    }
  };
}());

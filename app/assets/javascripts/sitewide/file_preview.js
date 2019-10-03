/* eslint no-underscore-dangle: ["error", { "allowAfterThis": true }]*/
/* eslint no-use-before-define: ["error", { "functions": false }]*/
/* eslint-disable no-underscore-dangle */
/* global Uint8Array fabric tui animateSpinner Assets ActiveStoragePreviews
   PerfectScrollbar MarvinJsEditor refreshProtocolStatusBar  */


var FilePreviewModal = (function() {
  'use strict';

  var readOnly = false;

  function initPreviewModal(options = {}) {
    var name;
    var url;
    var downloadUrl;
    readOnly = options.readOnly;

    $('.file-preview-link').off('click');
    $('.file-preview-link').click(function(e) {
      e.preventDefault();
      name = $(this).find('.attachment-label').text();
      url = $(this).data('preview-url');
      downloadUrl = $(this).attr('href');
      openPreviewModal(name, url, downloadUrl);
      return true;
    });

    $('#filePreviewModal').find('.preview-close').click(function() {
      $('#filePreviewModal').find('.file-preview-container').html('');
      $('#filePreviewModal').modal('hide');
      if (typeof refreshProtocolStatusBar === 'function') refreshProtocolStatusBar();
    });
  }

  // Adding rotation icon
  function updateFabricControls() {
    fabric.Object.prototype.drawBorders = function(ctx, styleOverride = {}) {
      var wh = this._calculateCurrentDimensions();
      var strokeWidth = 1 / this.borderScaleFactor;
      var width = wh.x + strokeWidth;
      var height = wh.y + strokeWidth;
      var drawRotatingPoint = typeof styleOverride.hasRotatingPoint !== 'undefined'
        ? styleOverride.hasRotatingPoint : this.hasRotatingPoint;
      var hasControls = typeof styleOverride.hasControls !== 'undefined'
        ? styleOverride.hasControls : this.hasControls;
      var rotatingPointOffset = typeof styleOverride.rotatingPointOffset !== 'undefined'
        ? styleOverride.rotatingPointOffset : this.rotatingPointOffset;
      var rotateHeight = -height / 2;
      ctx.save();
      ctx.strokeStyle = styleOverride.borderColor || this.borderColor;
      this._setLineDash(ctx, styleOverride.borderDashArray || this.borderDashArray, null);
      ctx.strokeRect(
        -width / 2,
        -height / 2,
        width,
        height
      );
      if (drawRotatingPoint && this.isControlVisible('mtr') && hasControls) {
        ctx.beginPath();
        ctx.moveTo(0, rotateHeight);
        ctx.lineTo(0, rotateHeight - rotatingPointOffset + 10);
        ctx.stroke();
      }
      ctx.restore();
      return this;
    };

    fabric.Object.prototype.drawControls = function(ctx) {
      var rotationImage = 'data:image/png;base64,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';
      var rotate = new Image();
      var rotateLeft;
      var rotateTop;
      var wh = this._calculateCurrentDimensions();
      var width = wh.x;
      var height = wh.y;
      var scaleOffset = this.cornerSize;
      var left = -(width + scaleOffset) / 2;
      var top = -(height + scaleOffset) / 2;
      var methodName = this.transparentCorners ? 'stroke' : 'fill';

      if (!this.hasControls) {
        return this;
      }
      ctx.save();
      ctx.strokeStyle = this.cornerColor;
      ctx.fillStyle = this.cornerColor;
      if (!this.transparentCorners) {
        ctx.strokeStyle = this.cornerStrokeColor;
      }
      this._setLineDash(ctx, this.cornerDashArray, null);

      // top-left
      this._drawControl(
        'tl',
        ctx,
        methodName,
        left,
        top
      );

      // top-right
      this._drawControl(
        'tr',
        ctx,
        methodName,
        left + width,
        top
      );

      // bottom-left
      this._drawControl(
        'bl',
        ctx,
        methodName,
        left,
        top + height
      );

      // bottom-right
      this._drawControl(
        'br',
        ctx,
        methodName,
        left + width,
        top + height
      );

      if (!this.get('lockUniScaling')) {
        // middle-top
        this._drawControl(
          'mt',
          ctx,
          methodName,
          left + width / 2,
          top
        );

        // middle-bottom
        this._drawControl(
          'mb',
          ctx,
          methodName,
          left + width / 2,
          top + height
        );

        // middle-right
        this._drawControl(
          'mr',
          ctx,
          methodName,
          left + width,
          top + height / 2
        );

        // middle-left
        this._drawControl(
          'ml',
          ctx,
          methodName,
          left,
          top + height / 2
        );
      }
      // middle-top-rotate
      if (this.hasRotatingPoint) {
        rotate.src = rotationImage;
        rotateLeft = left + width / 2 - 6;
        rotateTop = top - this.rotatingPointOffset - 6;
        ctx.drawImage(rotate, rotateLeft, rotateTop, 32, 32);
      }
      ctx.restore();

      return this;
    };
  }

  function preInitImageEditor(data) {
    $.ajax({
      url: data['download-url'],
      type: 'get',
      success: function(responseData) {
        var fileUrl = responseData;
        initImageEditor(data, fileUrl);
      }
    });
  }

  function initImageEditor(data, fileUrl) {
    var imageEditor;
    var ps;
    var blackTheme = {
      'common.bi.image': '',
      'common.bisize.width': '0',
      'common.bisize.height': '0',
      'common.backgroundImage': 'none',
      'common.backgroundColor': '#1e1e1e',
      'common.border': '0px',

      // header
      'header.backgroundImage': 'none',
      'header.backgroundColor': 'transparent',
      'header.border': '0px',

      // load button
      'loadButton.backgroundColor': '#fff',
      'loadButton.border': '1px solid #ddd',
      'loadButton.color': '#222',
      'loadButton.fontFamily': '\'Noto Sans\', sans-serif',
      'loadButton.fontSize': '12px',

      // download button
      'downloadButton.backgroundColor': '#fdba3b',
      'downloadButton.border': '1px solid #fdba3b',
      'downloadButton.color': '#fff',
      'downloadButton.fontFamily': '\'Noto Sans\', sans-serif',
      'downloadButton.fontSize': '12px',

      // main icons
      'menu.normalIcon.path': '/images/icon-d.svg',
      'menu.normalIcon.name': 'icon-d',
      'menu.activeIcon.path': '/images/icon-b.svg',
      'menu.activeIcon.name': 'icon-b',
      'menu.disabledIcon.path': '/images/icon-a.svg',
      'menu.disabledIcon.name': 'icon-a',
      'menu.hoverIcon.path': '/images/icon-c.svg',
      'menu.hoverIcon.name': 'icon-c',
      'menu.iconSize.width': '24px',
      'menu.iconSize.height': '24px',

      // submenu primary color
      'submenu.backgroundColor': '#1e1e1e',
      'submenu.partition.color': '#3c3c3c',

      // submenu icons
      'submenu.normalIcon.path': '/images/icon-d.svg',
      'submenu.normalIcon.name': 'icon-d',
      'submenu.activeIcon.path': '/images/icon-c.svg',
      'submenu.activeIcon.name': 'icon-c',
      'submenu.iconSize.width': '32px',
      'submenu.iconSize.height': '32px',

      // submenu labels
      'submenu.normalLabel.color': '#8a8a8a',
      'submenu.normalLabel.fontWeight': 'lighter',
      'submenu.activeLabel.color': '#fff',
      'submenu.activeLabel.fontWeight': 'lighter',

      // checkbox style
      'checkbox.border': '0px',
      'checkbox.backgroundColor': '#fff',

      // range style
      'range.pointer.color': '#fff',
      'range.bar.color': '#666',
      'range.subbar.color': '#d1d1d1',

      'range.disabledPointer.color': '#414141',
      'range.disabledBar.color': '#282828',
      'range.disabledSubbar.color': '#414141',

      'range.value.color': '#fff',
      'range.value.fontWeight': 'lighter',
      'range.value.fontSize': '11px',
      'range.value.border': '1px solid #353535',
      'range.value.backgroundColor': '#151515',
      'range.title.color': '#fff',
      'range.title.fontWeight': 'lighter',

      // colorpicker style
      'colorpicker.button.border': '1px solid #1e1e1e',
      'colorpicker.title.color': '#fff'
    };

    animateSpinner(null, true);
    imageEditor = new tui.ImageEditor('#tui-image-editor', {
      includeUI: {
        loadImage: {
          path: fileUrl,
          name: data.filename
        },
        theme: blackTheme,
        initMenu: 'draw',
        menuBarPosition: 'bottom'
      },
      cssMaxWidth: 700,
      cssMaxHeight: 500,
      selectionStyle: {
        cornerSize: 20,
        rotatingPointOffset: 70,
        borderColor: '#333',
        cornerColor: '#333',
        cornerStyle: 'circle',
        borderScaleFactor: 3

      },
      usageStatistics: false
    });

    imageEditor.on('image_loaded', () => {
      $('.file-save-link').css('display', '');
      animateSpinner(null, false);
    });

    ps = new PerfectScrollbar($('.tui-image-editor-wrap')[0], { wheelSpeed: 0.5 });
    $('#tui-image-editor .tui-image-editor').on('mousewheel', (e) => {
      var imageOriginalSize = {
        width: imageEditor._graphics.canvasImage.width,
        height: imageEditor._graphics.canvasImage.height
      };
      var wDelta = e.originalEvent.wheelDelta || e.originalEvent.deltaY;
      var imageEditorWindow = e.currentTarget;
      var scrollContainer = $('.tui-image-editor-wrap');
      var initWidth = imageEditorWindow.style.width;
      var initHeight = imageEditorWindow.style.height;

      var scrollContainerInitial = {
        top: scrollContainer.scrollTop(),
        left: scrollContainer.scrollLeft(),
        height: scrollContainer[0].scrollHeight,
        width: scrollContainer[0].scrollWidth
      };

      var mousePosition = {
        top: e.clientY - (imageEditorWindow.offsetTop - scrollContainerInitial.top),
        left: e.clientX - $(imageEditorWindow).offset().left
      };


      var newWidth;
      var newHeight;
      var offsetY;
      var offsetX;
      if (wDelta > 0) {
        newWidth = parseInt(initWidth, 10) * 1.1;
        newHeight = parseInt(initHeight, 10) * 1.1;
        if (newWidth > imageOriginalSize.width || newHeight > imageOriginalSize.height) {
          newWidth = imageOriginalSize.width;
          newHeight = imageOriginalSize.height;
        }
      } else {
        newWidth = parseInt(initWidth, 10) * 0.9;
        newHeight = parseInt(initHeight, 10) * 0.9;
        if (parseInt(imageEditorWindow.dataset.minWidth, 10) * 0.5 > parseInt(newWidth, 10)) {
          newWidth = parseInt(imageEditorWindow.dataset.minWidth, 10) * 0.5;
          newHeight = parseInt(imageEditorWindow.dataset.minHeight, 10) * 0.5;
        }
      }
      imageEditorWindow.style.width = newWidth + 'px';
      imageEditorWindow.style.height = newHeight + 'px';
      $(imageEditorWindow).find('canvas, .tui-image-editor-canvas-container')
        .css('max-width', imageEditorWindow.style.width)
        .css('max-height', imageEditorWindow.style.height);
      if (imageEditorWindow.dataset.minHeight === undefined) {
        imageEditorWindow.dataset.minHeight = initHeight;
        imageEditorWindow.dataset.minWidth = initWidth;
      }

      offsetY = (scrollContainer[0].scrollHeight - scrollContainerInitial.height)
      * (mousePosition.top / scrollContainerInitial.height);
      offsetX = (scrollContainer[0].scrollWidth - scrollContainerInitial.width)
      * (mousePosition.left / scrollContainerInitial.width);

      scrollContainer.scrollTop(scrollContainerInitial.top + offsetY);
      scrollContainer.scrollLeft(scrollContainerInitial.left + offsetX);

      ps.update();

      e.preventDefault();
      e.stopPropagation();
    });
    $('.tui-image-editor-wrap')[0].onwheel = function() { return false; };
    $('.tui-image-editor-wrap').css('height', 'calc(100% - 150px)');

    $('#fileEditModal').find('.file-name').text('Editing: ' + data.filename);
    $('#fileEditModal').modal('show');

    $('.tui-image-editor-header').hide();

    $('.file-save-link').css('display', 'none');
    $('.file-save-link').off().click(function(ev) {
      var imageBlob;
      var imageDataURL;
      var imageParams;
      var dataUpload = new FormData();
      var blobArray;
      var bytePosition;

      ev.preventDefault();
      ev.stopPropagation();

      if (data['mime-type'] === 'image/png') {
        imageParams = { format: 'png' };
      } else {
        imageParams = { format: 'jpeg', quality: (data.quality / 100) };
      }

      imageDataURL = imageEditor.toDataURL(imageParams);
      imageDataURL = atob(imageDataURL.split(',')[1]);

      blobArray = new Uint8Array(imageDataURL.length);

      for (bytePosition = 0; bytePosition < imageDataURL.length; bytePosition += 1) {
        blobArray[bytePosition] = imageDataURL.charCodeAt(bytePosition);
      }

      imageBlob = new Blob([blobArray]);

      function closeEditor() {
        animateSpinner(null, false);
        imageEditor.destroy();
        imageEditor = {};
        $('#tui-image-editor').html('');
        $('#fileEditModal').modal('hide');
      }

      dataUpload.append('image', imageBlob);
      animateSpinner(null, true);
      $.ajax({
        type: 'POST',
        url: '/files/' + data.id + '/update_image',
        data: dataUpload,
        contentType: false,
        processData: false,
        success: function(res) {
          $('#modal_link' + data.id).parent().html(res.html);
          initPreviewModal();
        }
      }).done(function() {
        closeEditor();
        
      });
      if (typeof refreshProtocolStatusBar === 'function') refreshProtocolStatusBar();
    });

    window.onresize = function() {
      imageEditor.ui.resizeEditor();
    };
  }

  function openPreviewModal(name, url, downloadUrl) {
    var modal = $('#filePreviewModal');
    updateFabricControls();
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        var link = modal.find('.file-download-link');
        clearPrevieModal();
        if (Object.prototype.hasOwnProperty.call(data, 'wopi-controls')) {
          modal.find('.file-wopi-controls').html(data['wopi-controls']);
        }
        link.attr('href', downloadUrl);
        link.attr('data-no-turbolink', true);
        link.attr('data-status', 'asset-present');
        if (data.type === 'previewable') {
          animateSpinner('.file-preview-container', false);
          modal.find('.file-preview-container')
            .append($('<img>')
              .css('opacity', 0)
              .attr('src', data['large-preview-url'])
              .attr('alt', name)
              .on('error', ActiveStoragePreviews.reCheckPreview)
              .on('load', ActiveStoragePreviews.showPreview)
              .click(function(ev) {
                ev.stopPropagation();
              }));
          if (!readOnly && data.editable) {
            modal.find('.file-edit-link').css('display', '');
            modal.find('.file-edit-link').off().click(function(ev) {
              $.post('/files/' + data.id + '/start_edit_image');
              ev.preventDefault();
              ev.stopPropagation();
              modal.modal('hide');
              preInitImageEditor(data);
            });
          } else {
            modal.find('.file-edit-link').css('display', 'none');
          }
        } else if (data.type === 'marvinjs') {
          openMarvinEditModal(data, modal);
        } else {
          modal.find('.file-edit-link').css('display', 'none');
          modal.find('.file-preview-container').html(data['preview-icon']);
        }
        if (readOnly) {
          modal.find('#wopi_file_edit_button').remove();
        }
        modal.find('.file-name').text(name);
        modal.modal();
        modal.find('a[disabled=disabled]').click(function(ev) {
          ev.preventDefault();
        });
        $('.modal-backdrop').last().css('z-index', modal.css('z-index') - 1);
      },
      error: function() {
        // TODO
      }
    });
  }

  function clearPrevieModal() {
    var modal = $('#filePreviewModal');
    modal.find('.file-preview-container').empty();
    modal.find('.file-wopi-controls').empty();
    modal.find('.file-edit-link').css('display', 'none');
  }

  function openMarvinEditModal(data, modal) {
    modal.find('.file-preview-container')
      .append($('<img>')
        .css('opacity', 0)
        .attr('src', data['large-preview-url'])
        .attr('alt', data.name)
        .on('error', ActiveStoragePreviews.reCheckPreview)
        .on('load', ActiveStoragePreviews.showPreview)
        .click(function(ev) {
          ev.stopPropagation();
        }));
    if (!readOnly && data.editable) {
      modal.find('.file-edit-link').css('display', '');
      modal.find('.file-edit-link').off().click(function(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        modal.modal('hide');
        $.post(data['update-url'] + '/start_editing');
        MarvinJsEditor.open({
          mode: 'edit',
          data: data.description,
          name: data.name,
          marvinUrl: data['update-url']
        });
      });
    } else {
      modal.find('.file-edit-link').css('display', 'none');
    }
  }

  return Object.freeze({
    init: initPreviewModal,
    imageEditor: initImageEditor
  });
}(window));

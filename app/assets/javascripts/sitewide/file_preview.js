//= require assets

(function(global) {
  'use strict';

  global.initPreviewModal = function initPreviewModal() {
    var name;
    var url;
    var downloadUrl;
    $('.file-preview-link').off('click');
    $('.file-preview-link').click(function(e) {
      e.preventDefault();
      name = $(this).find('p').text();
      url = $(this).data('preview-url');
      downloadUrl = $(this).attr('href');
      openPreviewModal(name, url, downloadUrl);
    });
  }

  function initImageEditor(data) {
    var imageEditor;
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

    imageEditor = new tui.ImageEditor('#tui-image-editor', {
      includeUI: {
        loadImage: {
          path: data['download-url'],
          name: data.filename
        },
        theme: blackTheme, // or whiteTheme
        menu: ['draw', 'text', 'shape', 'crop', 'flip', 'icon', 'filter'],
        initMenu: 'draw',
        menuBarPosition: 'bottom'
      },
      cssMaxWidth: 700,
      cssMaxHeight: 500,
      selectionStyle: {
        cornerSize: 20,
        rotatingPointOffset: 70
      },
      usageStatistics: false
    });

    $('#fileEditModal').find('.file-name').text('Editing: ' + data.filename);
    $('#fileEditModal').modal('show');

    $('.tui-image-editor-header').hide();

    $('.file-save-link').off().click(function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      animateSpinner(null, true);
      $.ajax({
        type: 'POST',
        url: '/files/' + data.id + '/update_image',
        data: {
          image: imageEditor.toDataURL()
        },
        success: function(res) {
          $('#modal_link' + data.id).parent().html(res.html);
          setupAssetsLoading();
        }
      }).done(function() {
        animateSpinner(null, false);
        imageEditor.destroy();
        imageEditor = {};
        $('#tui-image-editor').html('');
        $('#fileEditModal').modal('hide');
      });
    });

    window.onresize = function() {
      imageEditor.ui.resizeEditor();
    };
  }

  function openPreviewModal(name, url, downloadUrl) {
    var modal = $('#filePreviewModal');
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        modal.find('.file-preview-container').empty();
        modal.find('.file-wopi-controls').empty();
        if (data.hasOwnProperty('wopi-controls')) {
          modal.find('.file-wopi-controls').html(data['wopi-controls']);
        }
        var link = modal.find('.file-download-link');
        link.attr('href', downloadUrl);
        link.attr('data-no-turbolink', true);
        link.attr('data-status', 'asset-present');
        if (data.type === 'image') {
          if (data.processing) {
            animateSpinner('.file-preview-container', true);
          } else {
            animateSpinner('.file-preview-container', false);
            modal.find('.file-preview-container')
              .append($('<img>')
                .attr('src', data['large-preview-url'])
                .attr('alt', name)
                .click(function(ev) {
                  ev.stopPropagation();
                }));
            modal.find('.file-edit-link').off().click(function(ev) {
              ev.preventDefault();
              ev.stopPropagation();
              modal.modal('hide');
              initImageEditor(data);
            });
          }
        } else {
          modal.find('.file-preview-container').html(data['preview-icon']);
        }
        if (data.processing) {
          checkFileReady(url, modal);
        }
        modal.find('.file-name').text(name);
        modal.find('.preview-close').click(function() {
          modal.modal('hide');
        });
        modal.modal();
        $('.modal-backdrop').last().css('z-index', modal.css('z-index') - 1);
      },
      error: function(ev) {
        // TODO
      }
    });
  }

  function checkFileReady(url, modal) {
    $.get(url, function(data) {
      if (data.processing) {
        $('.file-download-link')
          .addClass('disabled-with-click-events')
          .attr('title', I18n.t('general.file.processing'))
          .click(function(ev) {
            ev.preventDefault();
            ev.stopPropagation();
          });
        setTimeout(function() {
          checkFileReady(url, modal);
        }, 10000);
      } else {
        if (data.type === 'image') {
          modal.find('.file-preview-container').empty();
          modal.find('.file-preview-container')
            .append($('<img>')
              .attr('src', data['large-preview-url'])
              .attr('alt', data.filename)
              .click(function(ev) {
                ev.stopPropagation();
              }));
          modal.find('.file-name').text(data.filename);
          modal.find('.modal-body').click(function() {
            modal.modal('hide');
          });
          modal.modal();
          $('.modal-backdrop').last().css('z-index', modal.css('z-index') - 1);
        }
        $('.file-download-link')
          .removeClass('disabled-with-click-events')
          .removeAttr('title')
          .off();
      }
    })
  }
}(window));

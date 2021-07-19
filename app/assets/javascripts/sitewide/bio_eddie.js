/* global HelperModule I18n */
var bioEddieEditor = (function() {
  var BIO_EDDIE;
  var CHEMAXON;
  var bioEddieIframe;
  var bioEddieModal;

  function importMolecule() {
    var monomerModel = BIO_EDDIE.getMonomerModel();
    var monomerImporter = new CHEMAXON.HelmImportModule();
    var molecule = bioEddieModal.data('molecule') || '';
    monomerImporter.import(molecule, monomerModel)
      .then(builder => BIO_EDDIE.setModel(builder.graphStoreData));
  }

  function loadBioEddie() {
    BIO_EDDIE = bioEddieIframe.contentWindow.bioEddieEditor;
    CHEMAXON = bioEddieIframe.contentWindow.chemaxon;

    if (typeof BIO_EDDIE === 'undefined' || typeof CHEMAXON === 'undefined') {
      setTimeout(function() {
        loadBioEddie();
      }, 2000);
    } else {
      importMolecule();
    }
  }

  function initIframe() {
    if (typeof BIO_EDDIE === 'undefined' || typeof CHEMAXON === 'undefined') {
      bioEddieIframe.src = bioEddieIframe.dataset.src;
      loadBioEddie();
    } else {
      importMolecule();
    }
  }

  function saveMolecule(svg, structure) {
    var moleculeName = bioEddieModal.find('.file-name input').val();
    $.post(bioEddieModal.data('create-url'), {
      description: structure,
      object_id: bioEddieModal.data('object_id'),
      object_type: bioEddieModal.data('object_type'),
      name: moleculeName,
      image: svg
    }, function(result) {
      var newAsset = $(result.html);
      if (bioEddieModal.data('object_type') === 'Step') {
        newAsset.find('.file-preview-link').css('top', '-300px');
        newAsset.addClass('new').prependTo($(bioEddieModal.data('assets_container')));
        setTimeout(function() {
          newAsset.find('.file-preview-link').css('top', '0px');
        }, 200);
        bioEddieModal.modal('hide');
      } else if (bioEddieModal.data('object_type') === 'Result') {
        window.location.reload();
      }
    });
  }

  function updateMolecule(svg, structure) {
    var moleculeName = bioEddieModal.find('.file-name input').val();
    $.ajax({
      url: bioEddieModal.data('update-url'),
      data: {
        description: structure,
        name: moleculeName,
        image: svg
      },
      dataType: 'json',
      type: 'PUT',
      success: function(json) {
        $('#modal_link' + json.id + ' img').attr('src', json.url);
        $('#modal_link' + json.id + ' .attachment-label').html(json.file_name);
        bioEddieModal.modal('hide');
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        }
      }
    });
  }

  function generateImage(structure) {
    var imageGenerator = new CHEMAXON.ImageGenerator();
    var emptySVG = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    imageGenerator.generateSVGFromHelm(emptySVG, structure)
      .then(svg => {
        if (bioEddieModal.data('edit-mode')) {
          updateMolecule(svg, structure);
        } else {
          saveMolecule(svg, structure);
        }
      });
  }

  $(document).on('turbolinks:load', function() {
    bioEddieIframe = document.getElementById('bioEddieIframe');
    bioEddieModal = $('#bioEddieModal');

    bioEddieModal.on('shown.bs.modal', function() {
      initIframe();
    });

    bioEddieModal.on('click', '.file-save-link', function() {
      var model = BIO_EDDIE.getModel();
      var monomerModel = BIO_EDDIE.getMonomerModel();
      var monomerExporter = new CHEMAXON.Helm2ExportModule();

      monomerExporter.export(model, monomerModel)
        .then(structure => generateImage(structure));
    });
  });

  return {
    open_new: (objectId, objectType, container) => {
      bioEddieModal.data('object_id', objectId);
      bioEddieModal.data('object_type', objectType);
      bioEddieModal.data('assets_container', container);
      bioEddieModal.find('.file-name input').val('');
      bioEddieModal.modal('show');
    },

    open_edit: (name, molecule, updateUrl) => {
      bioEddieModal.data('edit-mode', true);
      bioEddieModal.data('molecule', molecule);
      bioEddieModal.data('update-url', updateUrl);
      bioEddieModal.find('.file-name input').val(name);
      bioEddieModal.modal('show');

    }
  };
}());

(function() {
  $(document).on('click', '.new-bio-eddie-upload-button', function() {
    bioEddieEditor.open_new(
      this.dataset.objectId,
      this.dataset.objectType,
      this.dataset.assetsContainer
    );
  });

  $(document).on('click', '.bio-eddie-edit-button', function() {
    $('#filePreviewModal').modal('hide');
    bioEddieEditor.open_edit(
      this.dataset.moleculeName,
      this.dataset.moleculeDescription,
      this.dataset.updateUrl
    );
    $.post(this.dataset.editUrl);
  });
}());

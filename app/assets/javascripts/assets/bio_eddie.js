(function() {

  var BIO_EDDIE;

  function initBioEddie() {
    var config = {
      modules: {
          libraryManager: true,
          localStorage: true
      };
    };

    config.exportModules = [
      new chemaxon.Helm2ExportModule(),
      new chemaxon.Helm1ExportModule()
    ]

    BIO_EDDIE = chemaxon.bioEddie(document.getElementById('bio-eddie-editor'), config);
  }


  initBioEddie();
}());

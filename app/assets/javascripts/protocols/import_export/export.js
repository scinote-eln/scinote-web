//= require jszip.min.js

function exportProtocols(protocol_ids) {
  /*********************************************/
  /* INNER FUNCTIONS                           */
  /*********************************************/

  // Custom StringBuilder 'object'
  function StringBuilder() {
    this.tokens = [];

    this.add = function(token) {
      this.tokens.push(token);
      return this;
    };

    this.nl = function() {
      this.tokens.push('\n');
      return this;
    };

    this.build = function() {
      var str = this.tokens.join("");
      this.tokens = null;
      return str;
    };
  }

  function getGuid(id) {
    var str1 = "00000000-0000-";
    var str2 = id.toString();
    for (var i = str2.length; i < 19; i++) {
      str2 = "0" + str2;
    }
    str2 = "4" + str2;
    var str2n = str2.slice(0, 4) + "-" + str2.slice(4, 8) + "-" + str2.slice(8);
    return str1 + str2n;
  }

  // Escape null in String
  function esn(val) {
    if (val === null) {
      return "";
    } else {
      return String(val);
    }
  }

  function extractFileExtension(fileName) {
    var tokens = fileName.split(".");
    if (tokens.length <= 1) {
      return "";
    } else {
      return "." + tokens[tokens.length - 1];
    }
  }

  function generateEnvelopeXsd() {
    var sb = new StringBuilder();
    sb.add('<?xml version="1.0" encoding="UTF-8"?>').nl();
    sb.add('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">').nl();
    sb.add('<xs:element name="envelope">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="protocol" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:simpleContent>').nl();
    sb.add('<xs:extension base="xs:string">').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:extension>').nl();
    sb.add('</xs:simpleContent>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('<xs:attribute name="xmlns" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="version" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:schema>');
    return sb.build();
  }

  function generateElnXsd() {
    var sb = new StringBuilder();
    sb.add('<?xml version="1.0" encoding="UTF-8"?>').nl();
    sb.add('<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">').nl();
    sb.add('<xs:element name="eln">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="protocol">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="name" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="authors" type="xs:string" minOccurs="0"></xs:element>').nl();
    sb.add('<xs:element name="description" type="xs:string" minOccurs="0"></xs:element>').nl();
    sb.add('<xs:element name="created_at" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="updated_at" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="steps" minOccurs="0">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="step" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="name" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="description" type="xs:string" minOccurs="0"></xs:element>').nl();
    sb.add('<xs:element name="checklists" minOccurs="0">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="checklist" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="name" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="items" minOccurs="0">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="item" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="text" type="xs:string"></xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="position" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('<xs:element name="assets" minOccurs="0">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="asset" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="fileName" type="xs:string"></xs:element>').nl();
    sb.add('<xs:element name="fileType" type="xs:string"></xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="fileRef" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('<xs:element name="elnTables" minOccurs="0">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:sequence>').nl();
    sb.add('<xs:element name="elnTable" maxOccurs="unbounded">').nl();
    sb.add('<xs:complexType>').nl();
    sb.add('<xs:all>').nl();
    sb.add('<xs:element name="contents" type="xs:string"></xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="position" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:sequence>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="id" type="xs:int" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="guid" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:all>').nl();
    sb.add('<xs:attribute name="xmlns" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('<xs:attribute name="version" type="xs:string" use="required"></xs:attribute>').nl();
    sb.add('</xs:complexType>').nl();
    sb.add('</xs:element>').nl();
    sb.add('</xs:schema>');
    return sb.build();
  }

  /*********************************************/
  /* ACTUAL FUNCTION CODE                      */
  /*********************************************/

  if (protocol_ids.length > 0) {
    animateSpinner();

    $.ajax({
      type: "GET",
      url: "/protocols/export",
      dataType: "json",
      data: { protocol_ids: protocol_ids},
      success: function (data) {
        var zip = new JSZip();

        // Envelope code
        var esb = new StringBuilder();
        esb.add('<envelope xmlns="http://www.scinote.net" version="1.0">').nl();

        _.each(data.protocols, function(protocol) {
          var protocolGuid = getGuid(protocol.id);

          // Create folder for this protocol
          var protocolFolder = zip.folder(protocolGuid);

          var protocolXml = [];
          var psb = new StringBuilder();

          // Header
          psb.add('<eln xmlns="http://www.scinote.net" version="1.0">').nl();

          // Protocol
          psb.add('<protocol id="' + protocol.id + '" guid="' + protocolGuid + '">').nl();
          psb.add('<name>' + esn(protocol.name) + '</name>').nl();
          psb.add('<authors>' + esn(protocol.authors) + '</authors>').nl();
          psb.add('<description>' + esn(protocol.description) + '</description>').nl();
          psb.add('<created_at>' + esn(protocol.created_at) + '</created_at>').nl();
          psb.add('<updated_at>' + esn(protocol.updated_at) + '</updated_at>').nl();

          // Steps
          if (protocol.steps.length > 0) {
            psb.add('<steps>').nl();
            _.each(protocol.steps, function(step) {
              var stepGuid = getGuid(step.id);

              var ssb = new StringBuilder();

              ssb.add('<step id="' + step.id + '" guid="' + stepGuid + '" position="' + step.position + '">').nl();
              ssb.add('<name>' + esn(step.name) + '</name>').nl();
              ssb.add('<description>' + esn(step.description) + '</description>').nl();

              // Assets
              if (step.assets.length > 0) {
                ssb.add('<assets>').nl();
                _.each(step.assets, function(asset) {
                  var assetGuid = getGuid(asset.id);

                  // Generate the asset file inside ZIP
                  var assetFileName = assetGuid + extractFileExtension(asset.fileName);
                  var decodedData = window.atob(asset.bytes);
                  zip.folder(protocolGuid).folder(stepGuid).file(assetFileName, decodedData, { binary: true });

                  var asb = new StringBuilder();

                  asb.add('<asset id="' + asset.id + '" guid="' + assetGuid + '" fileRef="' + assetFileName + '">').nl();
                  asb.add('<fileName>' + esn(asset.fileName) + '</fileName>').nl();
                  asb.add('<fileType>' + esn(asset.fileType) + '</fileType>').nl();
                  asb.add('</asset>').nl();

                  ssb.add(asb.build());
                });
                ssb.add('</assets>').nl();
              }

              // Tables
              if (step.tables.length > 0) {
                ssb.add('<elnTables>').nl();
                _.each(step.tables, function(table) {
                  var tsb = new StringBuilder();

                  tsb.add('<elnTable id="' + table.id + '" guid="' + getGuid(table.id) + '">').nl();
                  tsb.add('<contents>' + esn(table.contents) + '</contents>').nl();
                  tsb.add('</elnTable>');

                  ssb.add(tsb.build()).nl();
                });
                ssb.add('</elnTables>').nl();
              }

              // Checklists
              if (step.checklists.length > 0) {
                ssb.add('<checklists>').nl();
                _.each(step.checklists, function(checklist) {
                  var csb = new StringBuilder();

                  csb.add('<checklist id="' + checklist.id + '" guid="' + getGuid(checklist.id) + '">').nl();
                  csb.add('<name>' + esn(checklist.name) + '</name>').nl();

                  if (checklist.items.length > 0) {
                    csb.add('<items>').nl();
                    _.each(checklist.items, function(item) {
                      var isb = new StringBuilder();

                      isb.add('<item id="' + item.id + '" guid="' + getGuid(item.id) + '" position="' + item.position + '">').nl();
                      isb.add('<text>' + esn(item.text) + '</text>').nl();
                      isb.add('</item>');

                      csb.add(isb.build()).nl();
                    });
                    csb.add('</items>').nl();
                  }
                  csb.add('</checklist>');

                  ssb.add(csb.build()).nl();
                });
                ssb.add('</checklists>').nl();
              }

              psb.add(ssb.build());
              psb.add('</step>').nl();
            });
            psb.add('</steps>').nl();
          }

          psb.add('</protocol>').nl();
          psb.add('</eln>');

          // Okay, we have a generated XML for
          // individual protocol, save it to protocol folder
          protocolFolder.file("eln.xml", psb.build());

          // Add protocol to the envelope
          esb.add('<protocol id="' + protocol.id + '" guid="' + protocolGuid + '">' + esn(protocol.name) + '</protocol>').nl();
        });
        esb.add('</envelope>').nl();

        // Save envelope to root directory in ZIP
        zip.file("scinote.xml", esb.build());

        // Add the XSD schemes into the ZIP
        zip.file("scinote.xsd", generateEnvelopeXsd());
        zip.file("eln.xsd", generateElnXsd());

        // NOW, DOWNLOAD THE ZIP
        var blob = zip.generate({ type: "blob" });

        var fileName = "protocol.eln";
        if (data.protocols.length === 1) {
          // Try to construct an OS-safe file name
          if (data.protocols[0].name.length && data.protocols[0].name.length > 0) {
            var escapedName = data.protocols[0].name.replace(/[^0-9a-zA-Z-.,_]/gi, '_').toLowerCase().substring(0, 250);
            if (escapedName.length > 0) {
              fileName = escapedName + ".eln";
            }
          }
        } else if (data.protocols.length > 1) {
          fileName = "protocols.eln";
        }

        var link = document.createElement("a");
        if (link.download !== undefined) {
          // Browsers that support HTML5 download attribute
          link.setAttribute("href", window.URL.createObjectURL(blob));
          link.setAttribute("download", fileName);
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        } else {
          alert("Please use latest version of Chrome, Firefox, or Opera browser for the export!");
        }

        animateSpinner(null, false);
      },
      error: function() {
        alert("Ajax error!");
      }
    });
  }
}
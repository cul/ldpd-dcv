import ArchivalIIIFViewer from "@archival-iiif/viewer-react";
$(document).ready(function(){
  var manifestUrl = $('#aiiif').data('manifest');
  if (manifestUrl) {
    new ArchivalIIIFViewer({id: 'aiiif', manifest: manifestUrl});
  }
});
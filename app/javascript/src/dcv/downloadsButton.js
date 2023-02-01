const LOG_THOUSAND = 1 / Math.log(1000);
const UNITS = ['B', 'Kb', 'Mb', 'Gb'];

function getListItemContentFromInfoRequestData(data) {
  var li_html = '';

  var sizes = data['sizes'];
  var sizeNames = ['small', 'medium', 'large', 'x-Large', 'xx-Large', 'xxx-Large']; // Probably more possible sizes than we will offer
  var iiifUrlTemplate = data['@id'] + '/full/_width_,_height_/0/native.jpg?download=true';
  for(var i = 0;i < sizes.length; i++){
    const dlName = sizeNames[i] + ' (' + sizes[i]['width'] + ' x ' + sizes[i]['height'] + ')';
    li_html += '<li class="dropdown-item"><a href="' + iiifUrlTemplate.replace('_width_', sizes[i]['width']).replace('_height_', sizes[i]['height']) + '" target="_blank" onclick="$(\'#dcvModal\').modal(\'hide\')"><span class="fa fa-download"></span> ' + dlName + '</a></li>';
  }

  return li_html;
}

function convertExtentToFileSize(extent) {
  const size = Number.parseInt(extent);
  var pow = Math.floor(Math.log(size) * LOG_THOUSAND);
  if (pow > 3) pow = 3;
  const fraction = (size/Math.pow(1000, pow)).toFixed(2);
  return fraction.toString() + UNITS[pow];
}

function getListItemContentFromDownloadsRequestData(data) {
  var li_html = '';
  data.forEach(function(resource) {
    const label = resource['size'] ? resource['title'] + ' (' + convertExtentToFileSize(resource['size']) + ')' : resource['title'];
    li_html += '<li class="dropdown-item"><a href="' + resource['url'] + '" target="_blank" onclick="$(\'#dcvModal\').modal(\'hide\')"><span class="fa fa-download"></span> ' + label + '</a></li>';
  });
  return li_html;
}

function getListItemForUrl(resourceUrl) {
  return '<li class="dropdown-item"><a href="' + resourceUrl + '" target="_blank" onclick="$(\'#dcvModal\').modal(\'hide\')"><span class="fa fa-download"></span> Download document</a></li>';
}

export default function() {
  if($('.download-button').length > 0) {
    //Set up download button
    $('#dcvModal').on('shown.bs.modal', function (event) {
      const downloadButton = $(event.relatedTarget);
      if (!downloadButton.hasClass('download-button')) return;
      const downloadsList = $('#downloads-list');
      if (downloadsList.hasClass('show')) return;
      //If data-download-info-url is present, that means that we're offering file downloads INSTEAD OF IIIF sizes
      var downloadInfoUrl = downloadButton.attr('data-download-info-url');
      var infoHandler = null;
      if(typeof(downloadInfoUrl) != 'undefined' && downloadInfoUrl.length > 0) {
        infoHandler = getListItemContentFromDownloadsRequestData;
      } else {
        downloadInfoUrl = downloadButton.attr('data-iiif-info-url');
        if(typeof(downloadInfoUrl) != 'undefined' && downloadInfoUrl.length > 0) {
          infoHandler = getListItemContentFromInfoRequestData;
        }
      }
      if (infoHandler) {
        downloadsList.html('<li class="dropdown-item">Loading...</li>');
        $.ajax({
          dataType: "json",
          url: downloadInfoUrl,
          success: function(data){
            downloadsList.html('');
            downloadsList.append(infoHandler(data));
            downloadButton.modal('handleUpdate');
          }
        });
      } else {
        downloadInfoUrl = downloadButton.attr('data-download-asset-url');
        if (downloadInfoUrl) downloadsList.html(getListItemForUrl(downloadInfoUrl));
      }
    });
  }
}

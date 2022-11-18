function getListItemContentFromInfoRequestData(data) {
  var li_html = '';

  var sizes = data['sizes'];
  var sizeNames = ['small', 'medium', 'large', 'x-Large', 'xx-Large', 'xxx-Large']; // Probably more possible sizes than we will offer
  var iiifUrlTemplate = data['@id'] + '/full/_width_,_height_/0/native.jpg?download=true';
  for(var i = 0;i < sizes.length; i++){
    const dlName = sizeNames[i] + ' (' + sizes[i]['width'] + ' x ' + sizes[i]['height'] + ')';
    li_html += '<li class="dropdown-item"><a href="' + iiifUrlTemplate.replace('_width_', sizes[i]['width']).replace('_height_', sizes[i]['height']) + '" target="_blank"><span class="fa fa-download"></span> ' + dlName + '</a></li>';
  }

  return li_html;
}

export default function() {
  if($('.download-button').length > 0) {
    //Set up download button
    $('.download-button').on('click', function(){
      const downloadButton = $(this);
      const downloadsList = $(this).siblings('.downloads-list');
      if (downloadsList.hasClass('show')) return;
      //If data-download-content-url is present, that means that we're offering a file download INSTEAD OF different image sizes

      if(typeof(downloadButton.attr('data-download-content-url')) != 'undefined' && downloadButton.attr('data-download-content-url').length > 0) {
        downloadsList.html('<li class="dropdown-item"><a class="dropdown-link" href="' + downloadButton.attr('data-download-content-url') + '" target="_new"><span class="fa fa-download"></span> Download File</a></li>');
      } else {
        downloadsList.html('<li class="dropdown-item">Loading...</li>');
        var iiifImageInfoUrl = downloadButton.attr('data-iiif-info-url');

        $.ajax({
          dataType: "json",
          url: iiifImageInfoUrl,
          success: function(data){
            downloadsList.html('');
            downloadsList.append(getListItemContentFromInfoRequestData(data));
            downloadButton.dropdown('update');
          }
        });
      }
    });
  }
}

function getListItemContentFromInfoRequestData(data) {
  var li_html = '';

  var sizes = data['sizes'];
  var sizeNames = ['small', 'medium', 'large', 'x-Large', 'xx-Large', 'xxx-Large']; // Probably more possible sizes than we will offer
  var iiifUrlTemplate = data['@id'] + '/full/_width_,_height_/0/native.jpg?download=true';
  for(var i = 0;i < sizes.length; i++){
    dlName = sizeNames[i] + ' (' + sizes[i]['width'] + ' x ' + sizes[i]['height'] + ')';
    li_html += '<li class="downloadItem"><a href="' + iiifUrlTemplate.replace('_width_', sizes[i]['width']).replace('_height_', sizes[i]['height']) + '" target="_blank"><span class="fa fa-download"></span> ' + dlName + '</a></li>'
  }

  return li_html;
}

export default function() {
  if($('#download-button').length > 0) {
    //Set up download button
    $('#download-button').on('click', function(){

      //If data-download-content-url is present, that means that we're offering a file download INSTEAD OF different image sizes

      if(typeof($(this).attr('data-download-content-url')) != 'undefined' && $(this).attr('data-download-content-url').length > 0) {
        $('#downloads-list').html('<li><a href="' + $(this).attr('data-download-content-url') + '" target="_new"><span class="fa fa-download"></span> Download File</a></li>');
      } else {
        $('#downloads-list').html('<li>Loading...</li>');
        var iiifImageInfoUrl = $(this).attr('data-iiif-info-url');

        $.ajax({
          dataType: "json",
          url: iiifImageInfoUrl,
          success: function(data){
            $('#downloads-list').html('');
            $('#downloads-list').append(getListItemContentFromInfoRequestData(data));
          }
        });
      }
    });
  }
}
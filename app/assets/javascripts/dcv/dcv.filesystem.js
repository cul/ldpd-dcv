window.DCV = window.DCV || function(){};
DCV.Filesystem = function(){};
DCV.Filesystem.folderHandler = function(){
  $(this).parent().children('UL').slideToggle({ done: function(){
    if ($(this).is(':visible')) $(this).parent().addClass('fs-expanded');
    else $(this).parent().removeClass('fs-expanded');
  }});
  return false;
}
DCV.Filesystem.fileHandler = function(){
  //TODO: modal for files
  url = $(this).attr('data-url') ? $(this).attr('data-url') : '/previews/' + encodeURIComponent($(this).attr('data-id'))
  DCV.Filesystem.modalPreview(url);
  return false;
}
DCV.Filesystem.bindHandlers = function() {
  //$('LI.fs-directory A').bind('click', DCV.Filesystem.folderHandler);
  $('LI.fs-file A.preview').bind('click', DCV.Filesystem.fileHandler);
}
DCV.Filesystem.modalPreview = function(dataUrl){

  $.colorbox({
    href: dataUrl,
    className: 'cul-no-colorbox-title-bar',
    height:"75%",
    width:"75%",
    maxHeight:"90%",
    maxWidth:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current: false,
    title: false
  });

  return false;
};
$(window).load(DCV.Filesystem.bindHandlers);
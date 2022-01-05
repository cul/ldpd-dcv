/*************************
 * DCV.ZoomingImageModal *
 *************************/
import ColorBox from "../jquery.colorbox";

const getCurrentZoomUrl = function() {
  var currentChild = $('#favorite-child').find('img');
  var url = new URL(currentChild.attr('data-zoom-url'));
  url.searchParams.append('initial_page', currentChild.attr('data-sequence'))
  return url.toString();
}

export const zoomingImageModal = function(){

  var zoomUrl = getCurrentZoomUrl();

  ColorBox.call($, {
    href: zoomUrl,
    height:"100vh",
    width:"90vw",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    close: '\uf00d',
    current:"{current} of {total}"
  });

  return false;
};

export const zoomingImageNewWindow = function() {
  window.open(getCurrentZoomUrl());
  return false;
};

export default zoomingImageModal;
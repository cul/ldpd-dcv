/*************************
 * DCV.ZoomingImageModal *
 *************************/

export const getCurrentZoomUrl = function(element) {
  const title = typeof element !== "undefined" ? false : true;
  var currentChild = $('#favorite-child').find('img');
  var url = new URL(currentChild.attr('data-zoom-url'));
  url.searchParams.append('title', title ? "true" : "false");
  url.searchParams.append('initial_page', currentChild.attr('data-sequence'))
  return url.toString();
}

export const zoomingImageNewWindow = function() {
  window.open(getCurrentZoomUrl());
  return false;
};

export default getCurrentZoomUrl;
import ColorBox from "./jquery.colorbox";
import videojs from 'video.js';

/**********************
 * CHILD VIEWER STUFF *
 **********************/

export default function () {
  var $childCarouselElement = $('#child-viewer-carousel');
  if ($childCarouselElement.length == 0) { return; }

  // Set up viewer carousel
  const onSlid = function () {
    // When the slider is triggered, pause any video/audio elements in the carousel that are currently playing.
    $(this).find('video, audio').each(function () {
      const videoJsPlayer = getVideoJsPlayerForElement($(this)[0]);
      if (videoJsPlayer) {
        videoJsPlayer.pause();
      }
    });

    var $currentSlideElememt = $childCarouselElement.find('.carousel-item.active');
    var childNumber = parseInt($currentSlideElememt.attr('data-child-number'));
    //Remove selected class from previous gallery item
    $('#child_gallery a[rel="item-link"].selected').removeClass('selected');
    $('#child_gallery a[rel="item-link"][data-child-number="' + childNumber + '"]').addClass('selected');

    //Update title, zoom links
    $('#child-viewer-subtitle').html($currentSlideElememt.attr('data-child-title'));
    if ($currentSlideElememt.attr('data-has-details') == 'true') {
      $('#child-zoom-modal-button').attr('href', $currentSlideElememt.attr('data-zoom-url')).show();
      $('#child-zoom-new-window-button').attr('href', $currentSlideElememt.attr('data-zoom-url')).show();
    } else {
      $('#child-zoom-modal-button').hide();
      $('#child-zoom-new-window-button').hide();
    }

    //Update download link
    if ($currentSlideElememt.attr('data-has-iiif') == 'true') {
      $('#download-button').attr('data-download-content-url', ''); //Clear out previous download content url value if present
      $('#download-button').attr('data-iiif-info-url', $currentSlideElememt.attr('data-iiif-info-url'))
      $('#download-button-group').show();
    } else if ($currentSlideElememt.attr('data-download-content-url').length > 0) {
      $('#download-button').attr('data-download-content-url', $currentSlideElememt.attr('data-download-content-url'));
      $('#download-button-group').show();
    } else {
      $('#download-button-group').hide();
    }

    //Update item in context value, but don't show the link if it points to the current page
    if ($currentSlideElememt.attr('data-object-in-context-url').length > 0 && window.location.href != $currentSlideElememt.attr('data-object-in-context-url')) {
      $('#child-viewer-object-in-context').html('View Object in Context').attr('href', $currentSlideElememt.attr('data-object-in-context-url'));
    } else {
      $('#child-viewer-object-in-context').html('&nbsp;').attr('href', '#');
    }
  }
  const carouselOpts = {
    interval: false // Do not automatically cycle
  };
  $childCarouselElement.on('slid.bs.carousel', onSlid).carousel(carouselOpts);


  $childCarouselElement.on('click', 'img.zoomable', function () {
    $('#child-zoom-modal-button').click(); //Clicking on the image itself is the same as clicking on the modal zoom button
  });

  // Set up viewer gallert links
  $('#child_gallery a[rel="item-link"]').on('click', function () {
    $childCarouselElement.carousel(parseInt($(this).attr('data-child-number')));
  });

  //Set up new window zoomable image button
  $('#child-zoom-new-window-button').on('click', function (e) {
    e.preventDefault();
    window.open($(this).attr('href'));
  });

  //Set up modal zoomable image button
  $('#child-zoom-modal-button').on('click', function (e) {
    e.preventDefault();
    ColorBox.call($, {
      href: $(this).attr('href'),
      height: "100vh",
      width: "90vw",
      opacity: ".6",
      fixed: true,
      iframe: true,
      preloading: false,
      close: '\uf00d'
    });
  });

  //Manually trigger slide load event for carousel so event function runs
  $childCarouselElement.trigger('slid.bs.carousel');
}

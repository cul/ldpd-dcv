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

    //Update title
    $('#child-viewer-subtitle').html($currentSlideElememt.attr('data-child-title'));
  }
  const carouselOpts = {
    interval: false // Do not automatically cycle
  };
  $childCarouselElement.on('slid.bs.carousel', onSlid).carousel(carouselOpts);


  $childCarouselElement.on('click', 'img.zoomable', function () {
    $childCarouselElement.find('.item-modal').click(); //Clicking on the image itself is the same as clicking on the modal zoom button
  });

  // Set up viewer gallert links
  $('#child_gallery a[rel="item-link"]').on('click', function () {
    $childCarouselElement.carousel(parseInt($(this).attr('data-child-number')));
  });

  //Manually trigger slide load event for carousel so event function runs
  $childCarouselElement.trigger('slid.bs.carousel');
}

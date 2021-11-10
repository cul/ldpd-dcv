/*****************
 * LAZY BANNER CAROUSEL *
 *****************/
function bannerCarousel() {
  $('#banner-carousel').carousel({ interval: false }).on('slide.bs.carousel', function (ev) {
    var img = $(ev.relatedTarget).find("img[data-src]")[0];
    if (img && img.getAttribute('data-src') && !img.getAttribute('src')) {
      img.setAttribute('src', img.getAttribute('data-src'));
    }
  });
}

$(document).ready(function(){
  bannerCarousel();
});

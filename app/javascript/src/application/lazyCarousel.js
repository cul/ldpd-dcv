import 'bootstrap/js/dist/carousel';
/*****************
 * LAZY CAROUSEL *
 *****************/
export default function lazyCarousel(elementId) {
  const changeHandler = function (ev) {
    var img = $(ev.relatedTarget).find("img[data-src]")[0];
    if (img && !img.getAttribute('src')) {
      img.setAttribute('src', img.getAttribute('data-src'));
    }
  };
  const slidHandler = function (ev) { console.log("slid"); };
  $(elementId).carousel({ interval: false }).on('slide.bs.carousel', changeHandler).on('cycle.bs.carousel', slidHandler);
}
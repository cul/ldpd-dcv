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
  const carouselOpts = { interval: false };
  $(elementId).on('slide.bs.carousel', changeHandler).carousel(carouselOpts);
}
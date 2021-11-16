/****************************
 * Dcv.CitationDisplayModal *
 ****************************/
import ColorBox from "../jquery.colorbox";

export const show = function(citationDisplayUrl, modalLabel){

  ColorBox.call($, {
    href: citationDisplayUrl,
    height:"90%",
    maxHeight:'300px',
    width:"90%",
    maxWidth:"1200px",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current:"{current} of {total}",
    close: '\uf00d',
    title: modalLabel
  });

  return false;
};

export default function(element) {
  return show($(element).attr("href"), $(element).attr("data-label"))
}
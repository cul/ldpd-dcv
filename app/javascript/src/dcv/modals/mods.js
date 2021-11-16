/*************************
 * DCV.ModsDownloadModal *
 *************************/
import ColorBox from "../jquery.colorbox";

export const show = function(displayUrl, downloadUrl){

  ColorBox.call($, {
    href: displayUrl,
    height:"90%",
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    close: '\uf00d',
    title: '<a href="' + downloadUrl + '" data-no-turbolink="true"><span class="fa fa-download"></span> Download XML</a>'
  });

  return false;
};

export default function(element) {
  return show($(element).attr("data-display-url"), $(element).attr("data-download-url"));
}
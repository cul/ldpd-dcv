// import clipboardFromElement from "./clipboard";
// import DcvModals from "./dcv.modals";
// import { zoomingImageNewWindow } from "./modals/zoomingImage";
// import { initTiles } from './dcv.show.zooming_viewer';
import './dcv.general';
// window.clipboardFromElement = clipboardFromElement;
// window.initTiles = initTiles;
// window.zoomingImageNewWindow = zoomingImageNewWindow;

// readyHandlers.forEach(handler => $(document).ready(handler));
// $(document).ready(function () {
//   // make modals draggable
//   $("#dcvModal").draggable({
//     handle: "#dcvModalWrapper"
//   });
//   $('#dcvModal').on('show.bs.modal', function (event) {
//     const modalSizes = ['small', 'large', 'xl', 'max'];
//     var button = $(event.relatedTarget); // Button that triggered the modal
//     var modal = $(this);
//     modal.find('.modal-title').html(DcvModals.titleFor(button));
//     modal.find('.modal-body').html(DcvModals.bodyFor(button));
//     if (DcvModals.needsSize(button)) {
//       const modalSize = $(button).data('modal-size');
//       const modalDialog = modal.find('.modal-dialog');
//       modalSizes.forEach(size => (size == modalSize) ? modalDialog.addClass('modal-' + size) : modalDialog.removeClass('modal-' + size));
//     } else {
//       modalSizes.forEach(size => modal.find('.modal-dialog').removeClass('modal-' + size));
//     }
//     if (DcvModals.needsEmbed(button)) {
//       modal.find('.modal-content').addClass('mh-100');
//     } else {
//       modal.find('.modal-content').removeClass('mh-100');
//     }
//     modal.modal('handleUpdate');
//   });
// });




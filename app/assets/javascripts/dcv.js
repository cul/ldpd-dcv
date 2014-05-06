$(function() {
  $('#view-options #list-mode').on('click', function() {
      $('#content .col-sm-3').addClass('col-sm-12').addClass('list-view');
      $('#content .col-sm-3 .thumbnail').addClass('col-sm-2');
      $('#content .col-sm-3 .index-title').addClass('col-sm-10');
      $('#grid-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
  $('#view-options #grid-mode').on('click', function() {
      $('#content .col-sm-3').removeClass('col-sm-12').removeClass('list-view');
      $('#content .col-sm-3 .thumbnail').removeClass('col-sm-2');
      $('#content .col-sm-3 .index-title').removeClass('col-sm-10');
      $('#list-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
});

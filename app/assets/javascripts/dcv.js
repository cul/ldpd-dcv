$(function() {
  $('body').on('click', '#list-mode', function() {
      $('#content .col-sm-3').addClass('col-sm-12').addClass('list-view');
      $('#content .col-sm-3 .thumbnail').addClass('col-sm-2');
      $('#content .col-sm-3 .index-title').addClass('col-sm-10');
      $('#grid-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
  $('body').on('click', '#grid-mode', function() {
      $('#content .col-sm-3').removeClass('col-sm-12').removeClass('list-view');
      $('#content .col-sm-3 .thumbnail').removeClass('col-sm-2');
      $('#content .col-sm-3 .index-title').removeClass('col-sm-10');
      $('#list-mode').removeClass('btn-success').addClass('btn-default');
      $(this).addClass('btn-success');
  });
});

<!-- CULTNBW START -->
  CULh_colorfg = '#000000'; // topnavbar foreground color. hex value. ex: #002B7F
  CULh_colorbg = '#444444'; // topnavbar background color. hex value. ex: #779BC3
  CULh_nobs = 1; // uncomment to NOT load our bootstrap javascript file and or use your own (v2.3.x required)
<!-- /CULTNBW END -->

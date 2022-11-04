export const fileSystemReady = function() {
  var ttable = $('.file-system').stupidtable();
  ttable.on("aftertablesort", function (event, data) {
        var th = $(this).find("th");
        th.find(".arrow").remove();
        var dir = $.fn.stupidtable.dir;
        var arrow = data.direction === dir.ASC ? " &uarr;" : " &darr;";
        th.eq(data.column).append('<span class="arrow">' + arrow +'</span>');
      });  
};

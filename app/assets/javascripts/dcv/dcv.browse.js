window.DCV = window.DCV || function(){};
DCV.Browse = function(){};
DCV.Browse.PseudoFacet = function(){};
DCV.Browse.PseudoFacet.constrainTo = function(klass) {
  var value = (klass == "project-dcv") ? "Yes" : "No";
  var hide = 'div.' + ((klass == "project-dcv") ? "project-external" : "project-dcv");
  var facetHide = (klass == "project-dcv") ? "#dcv-no" : "#dcv-yes";
  var facetSelected = (klass == "project-dcv") ? "#dcv-yes" : "#dcv-no";
  $('#pseudo-facet').empty();
  $('#pseudo-facet').append('<span class="btn-group appliedFilter constraint filter"></span>')
  $('#pseudo-facet span.appliedFilter').append('<a href="#" class="constraint-value btn btn-sm btn-default btn-disabled"></a>');
  $('#pseudo-facet span.appliedFilter a.constraint-value').append('<span class="filterName">Content in DCV</span>');
  $('#pseudo-facet span.appliedFilter a.constraint-value').append('<span class="filterValue">' + value +'</span>');
  $('#pseudo-facet span.appliedFilter').append('<a href="#" onclick="DCV.Browse.PseudoFacet.unClick(); return false;" class="btn btn-default btn-sm remove dropdown-toggle"></a>');  
  $('#pseudo-facet span.appliedFilter a.remove').append('<span class="glyphicon glyphicon-remove"></span>');
  $(hide).hide();
  $(facetHide).hide();
  $(facetSelected + ' span.facet-label a').addClass('btn-disabled selected');

}
DCV.Browse.PseudoFacet.onClickLocal = function() {
	DCV.Browse.PseudoFacet.constrainTo('project-dcv');

}
DCV.Browse.PseudoFacet.onClickExternal = function() {
  DCV.Browse.PseudoFacet.constrainTo('project-external');
}
DCV.Browse.PseudoFacet.unClick = function() {
  $('#pseudo-facet').empty();
  $('div[itemtype="project"]').show();
  $('ul.facet-values li span.facet-label a').removeClass('btn-disabled selected');
  $('ul.facet-values li').show();
}

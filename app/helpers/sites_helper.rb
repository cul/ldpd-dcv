module SitesHelper
	def collapse_labels(label_obj = "")
		"<span class=\"collapsed-label\">Show #{label_obj}<i class=\"fa fa-angle-right\"></i></span>
        <span class=\"show-label\">Hide #{label_obj}<i class=\"fa fa-angle-down\"></i></span>".html_safe
	end
end
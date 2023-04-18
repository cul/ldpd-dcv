module SitesHelper
	def collapse_labels(label_obj = "")
		"<span class=\"collapsed-label\">Show #{label_obj}<i class=\"fa fa-angle-right\"></i></span>
        <span class=\"show-label\">Hide #{label_obj}<i class=\"fa fa-angle-down\"></i></span>".html_safe
	end
	def repository_display_value(repository_id)
		repo_code = repository_id.downcase.gsub('-', '')
		t("cul.archives.display_value.#{repo_code}", default: nil)
	end
	def repository_email_contact(repository_id)
		repo_code = repository_id.downcase.gsub('-', '')
		t("cul.archives.contact_email.#{repo_code}", default: nil)
	end
	def repository_physical_location(repository_id)
		repo_code = repository_id.downcase.gsub('-', '')
		t("cul.archives.physical_location.#{repo_code}", default: nil)
	end
end
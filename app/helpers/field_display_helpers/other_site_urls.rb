module FieldDisplayHelpers::OtherSiteUrls
  def show_link_to_other_site_home(args={})
    values = Array(args[:value])
    document = args[:document]
    values.map do |site|
      next if site == @subsite
      display_label = site.title
      link_label = "#{display_label} <sup class=\"fa fa-external-link\" aria-hidden=\"true\"></sup>"
      link_to(link_label.html_safe, site_url(slug: site.slug), target: "_blank", rel: "noopener noreferrer")
    end.compact
  end
end

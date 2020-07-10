module Dcv
  # Create <link rel="alternate"> links from a documents dynamically
  class LinkAlternatePresenter < Blacklight::LinkAlternatePresenter
    # Renders links to alternate representations 
    # provided by export formats. Returns empty string if no links available.
    def render
      seen = Set.new

      safe_join(document.export_formats.map do |format, spec|
        next if options[:exclude].include?(format) || (options[:unique] && seen.include?(spec[:content_type]))

        seen.add(spec[:content_type])

        tag(:link, rel: "alternate", title: format, type: spec[:content_type], href: href(format))
      end.compact, "\n")
    end

    def href(format)
      href_params = view_context.search_state.url_for_document(document).merge(format: format)
      # link to sites controller for site results, restricted namespace dealt with in view context
      if document.site_result?
        href_params.merge!(controller: 'sites', slug: document.unqualified_slug, action: 'home')
        href_params.delete(:id)
      end
      view_context.url_for(href_params)
    end
  end
end

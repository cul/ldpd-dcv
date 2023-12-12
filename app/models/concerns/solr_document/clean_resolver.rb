module SolrDocument::CleanResolver
  # Scrub permanent links from catalog data to use modern resolver syntax
  # @param perma_link [String] the original link
  # @return [String] link with cgi version of resolver replaced with modern version
  def clean_resolver(link_src)
    if link_src
      link_uri = URI(link_src)
      if link_uri.path == "/cgi-bin/cul/resolve" && link_uri.host == "www.columbia.edu"
        return "https://resolver.library.columbia.edu/#{link_uri.query}"
      end
      if link_uri.host == "library.columbia.edu" && link_uri.path =~ /^\/resolve\/([^\/]+)/
        return "https://resolver.library.columbia.edu/#{$1}"
      end
    end
    link_src
  end
end

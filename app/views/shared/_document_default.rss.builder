xml.item do  
  xml.title(document_presenter(document).heading || (document.to_semantic_values[:title].first if document.to_semantic_values.key?(:title)))
  xml.link(href: url_for(url_for_document(document)))
  xml.pubDate(document[:system_modified_dtsi])
  xml.lastBuildDate(document[:timestamp])
  xml.author( document.to_semantic_values[:author].first ) if document.to_semantic_values.key? :author
end

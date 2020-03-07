module Dcv::FacetsHelperBehavior

  ## !Override
  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::SolrResponse::Facets::FacetField]
  # @param [String] facet item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_value(facet_field, item, options ={})
    # Check for specially-defined values to hide for this facet field. Return nil to hide the value.
    values_to_hide_for_this_facet = facet_configuration_for_field(facet_field)['cul_custom_value_hide']
    values_to_hide_for_this_facet = [] if values_to_hide_for_this_facet.nil?
    return nil if values_to_hide_for_this_facet.present? && values_to_hide_for_this_facet.include?(item.value)

    path = path_for_facet(facet_field, item)
    content_tag(:span, :class => "facet-label") do
      link_to_unless(options[:suppress_link], facet_display_value(facet_field, item), path, :class=>"facet_select")
    end + render_facet_count(item.hits)
  end

end

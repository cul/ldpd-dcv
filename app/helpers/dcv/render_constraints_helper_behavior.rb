module Dcv::RenderConstraintsHelperBehavior

  ## !Override
  # Check if the query has any constraints defined (a query, facet, etc)
  #
  # @param [Hash] query parameters
  # @return [Boolean]
  def query_has_constraints?(localized_params = params)
    !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:start_year].blank? and localized_params[:end_year].blank?)
  end

end

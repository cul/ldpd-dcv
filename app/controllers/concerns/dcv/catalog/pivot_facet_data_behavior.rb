module Dcv::Catalog::PivotFacetDataBehavior
  extend ActiveSupport::Concern

  # GET /catalog/get_pivot_facet_data.json?fields=facet1,facet2,facet3&top_level_field_name=Name
  def get_pivot_facet_data

    json_response = {}

    facets_to_pivot_on = params[:fields]
    top_level_field_name = params[:top_level_field_name] || 'Top Level'

    if facets_to_pivot_on && facets_to_pivot_on.split(',').length < 2
      json_response['error'] = 'Pivot facet requires at least two fields.'
    else
      rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']
      first_facet = facets_to_pivot_on.split(',')[0]
      top_level_field_name = blacklight_config.facet_fields[first_facet]
      if (top_level_field_name)
        top_level_field_name = top_level_field_name.label
      else
        top_level_field_name = 'Top Level'
      end      
      begin
        # Do solr query for each repository
        response = rsolr.get 'select', :params => {
          :q  => '*:*',
          :fl => 'id',
          :qt => 'search',
          :fq => [
            '-active_fedora_model_ssi:GenericResource' # Not retrieving file assets
          ],
          :rows => 0,
          :facet => true,
          :'facet.pivot' => facets_to_pivot_on
        }

        if response['response']['numFound'].to_i > 0
          facets = response['facet_counts']['facet_pivot'][facets_to_pivot_on]
          children = facets.collect {|facet| {name: facet['value'], size: facet['count'], field: facet['field']}}
          children = facets.map {|facet| build_child(facet)}
          json_response = {name: top_level_field_name, children: children}
        end

      rescue => error_response
        json_response = {'error' => 'Solr error (most likely caused by invalid parameter values).)'}
      end

    end

    respond_to do |format|
      format.json {
        render json: json_response
      }
      format.any {
        render :text => 'JSON is the only format available.', :status => 406
      }
    end

  end

  def build_child(facet)
    return (facet['pivot'] and facet['pivot'].length > 1) ?
     {name:facet['value'], field:facet['field'], children: facet['pivot'].map{|p|build_child(p)}} :
     {name: facet['value'], field:facet['field'], size: facet['count']}
  end

end

module Dcv::Components
  module FacetItemBehavior
    def suppress_value_display?
      facet_config['cul_custom_value_hide']&.include?(@facet_item.value)
    end

    def render?
      super && !suppress_value_display?
    end

    def label
      facet_transforms = facet_config['cul_custom_value_transforms']
      if facet_transforms
        return facet_transforms.inject(@facet_item.value) { |memo, transform| send "#{transform}_facet_value".to_sym, memo, facet_config }
      end
      @label
    end

    def capitalize_facet_value(value, facet_config)
      value.to_s.split(' ').map(&:capitalize).join(' ')
    end

    def singularize_facet_value(value, facet_config)
      value.to_s.singularize
    end

    def translate_facet_value(value, facet_config)
      return value unless facet_config['translation']
      ActiveSupport::HashWithIndifferentAccess.new(I18n.t(facet_config['translation']))[value] || value
    end    
  end
end
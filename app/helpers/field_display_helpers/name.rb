module FieldDisplayHelpers::Name
  # Pull indexable names, hash to roles
  NAME_VALUE_STRUCT = { fields: [], roles: [] }.freeze

  def display_names_with_roles(args={})
    document = args.fetch(:document,{})
    exclusions = args.fetch(:exclusions, []).map(&:capitalize)
    names = args.fetch(:value,[]).inject({}) { |memo, name| memo[name] = NAME_VALUE_STRUCT.deep_dup; memo }
    document.to_h.each do |f,v|
      next unless f =~ /role_.*_ssim/
      role = f.split('_')
      role.shift
      role.pop
      role = role[0].present? ? role.join(' ') : nil
      v.each do |name|
        next unless role && names[name]
        names[name][:fields] << f
        names[name][:roles] << role.capitalize if role && names[name]
      end
    end

    field = args[:field]
    case controller.action_name.to_sym
    when :index
      field_config = blacklight_config.index_fields[args[:field]]
    when :home
      field_config = blacklight_config.index_fields[args[:field]]
    else
      field_config = blacklight_config.show_fields[args[:field]]
    end

    default_field = field_config.link_to_facet if blacklight_config.facet_fields[field_config.link_to_facet]
    names.map do |name, role_info|
      facet_field = role_info[:fields].detect { |field_name| blacklight_config.facet_fields[field_name]} || default_field
      value = (!args[:suppress_links] && facet_field) ?
        link_to(name, controller.url_for(action: :index, f: { facet_field => [name] })) :
        name.dup
      roles = role_info[:roles]
      value << " (#{roles.join(',')})" unless roles.empty?
      value.html_safe 
      value if roles.empty? or roles.detect { |role| !exclusions.include?(role) }
    end.compact
  end

  # Pull indexabl non-copyrighte names, hash to roles
  def display_non_copyright_names_with_roles(args={})
    display_names_with_roles(args.merge(exclusions: ['Copyright Holder']))
  end

  def has_non_copyright_names?(field_config, document)
    args = {field: field_config.field, document: document, suppress_links: true}
    values = document[field_config.field]
    args[:value] = values if values
    values = display_non_copyright_names_with_roles(args)
    values.present?
  end

end

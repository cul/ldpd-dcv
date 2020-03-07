module FieldDisplayHelpers::Name
  # Pull indexable names, hash to roles
  def display_names_with_roles(args={})
    document = args.fetch(:document,{})
    exclusions = args.fetch(:exclusions, []).map(&:capitalize)
    names = args.fetch(:value,[]).map {|name| [name,[]]}.to_h
    document.to_h.each do |f,v|
      next unless f =~ /role_.*_ssim/
      role = f.split('_')
      role.shift
      role.pop
      role = role[0].present? ? role.join(' ') : nil
      v.each { |name| names[name] << role.capitalize if role && names[name] }
    end
    field = args[:field]
    field_config = (controller.action_name.to_sym == :index) ?
      blacklight_config.index_fields[args[:field]] :
      blacklight_config.show_fields[args[:field]]
    names.map do |name, roles|
      value = (!args[:suppress_links] && field_config.link_to_search) ?
        link_to(name, controller.url_for(action: :index, f: { field_config.link_to_search => [name] })) :
        name.dup
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

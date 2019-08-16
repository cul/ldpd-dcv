module FieldDisplayHelpers::Rights
  def rightsstatements_label(value)
    Rails.application.config_for(:copyright)[value]
  end

  def display_as_link_to_rightsstatements(args={})
    values = Array(args[:value])
    document = args[:document]
    values.map { |value| link_to(rightsstatements_label(value), value, target: "_new") }
  end
end
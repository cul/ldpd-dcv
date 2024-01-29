module FieldDisplayHelpers::Note
  def show_date_field(args)
    note_field = 'lib_date_notes_ssm'
    values = args[:document][args[:field]]
    notes = args[:document][note_field]
    (Array(values) + Array(notes)).compact.join('; ')
  end

  def notes_label(document, opts)
    field = opts[:field]
    type = field.split('_')[1..-3].join(' ').capitalize
    if type.eql?('Untyped')
      "Note"
    else
      "Note (#{type})"
    end
  end
end

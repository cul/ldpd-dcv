module Lcaaj::FieldFormatterHelper
  def lcaaj_format_form_document_type(value)
    if value == 'printouts'
		  'Computer Printout'
    elsif value == 'manuscripts'
  		nil
    else
      value.split(' ').map(&:capitalize).join(' ').singularize
    end
  end
end

module Dcv::TextTruncateHelper

  def truncate_text_to_250(args)
    truncate_text_to_length(250, args)
  end

  def truncate_text_to_400(args)
    truncate_text_to_length(400, args)
  end

  def truncate_text_to_length(truncation_length, args)    
    field_value = args[:document][args[:field]]
    text_arr = field_value.is_a?(Array) ? field_value : [field_value]
    
    arr_to_return = []
    text_arr.each do |text|
      if text.length > truncation_length
        arr_to_return.push(text[0..truncation_length] + '...')
      else
        arr_to_return.push(text)
      end
    end

    return field_value.is_a?(Array) ? arr_to_return : arr_to_return[0]
  end

  def expandable_past_250(args)
    return expandable_past_length(250, args)
  end

  def expandable_past_400(args)
    return expandable_past_length(400, args)
  end

  def expandable_past_length(truncation_length, args)
    field_value = args[:document][args[:field]]
    text_arr = field_value.is_a?(Array) ? field_value : [field_value]

    arr_to_return = []
    text_arr.each_with_index do |text, ix|
      if text.length > truncation_length
        span_prefix = args[:document][:id].dup
        span_prefix.gsub!(/[^A-Za-z0-9]/,'_')
        span_id = "#{span_prefix}-#{args[:field]}-collapse-#{ix}"
        span = collapsible_span(span_id, text[(truncation_length + 1)..-1])
        span.unshift(text[0..truncation_length])
        arr_to_return.concat(span)
      else
        arr_to_return.push(text)
      end
    end

    return arr_to_return.join.html_safe
  end

  def collapsible_span(span_id, text_overflow)
    [content_tag(:span,text_overflow, class: 'collapse', id: span_id), collapse_toggle(span_id)]
  end

  def collapse_toggle(span_id)
    atts = {
      class: "btn btn-xs btn-link",
      role: "button",
      :"data-toggle" => "collapse",
      :"data-target" => "##{span_id}",
      :"aria-expanded" => "false",
      :"aria-controls" => span_id
    }
    content_tag(:button, atts) do
      content_tag(:span, "&raquo; Show more".html_safe, class: "collapsed") << content_tag(:span, " &laquo; Show less".html_safe, class: "expanded")
    end
  end
end

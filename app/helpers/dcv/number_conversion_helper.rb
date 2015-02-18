module Dcv::NumberConversionHelper

  def byte_size_to_text_string(size_in_bytes)
    if size_in_bytes > 1000000000
      return (size_in_bytes/1000000000).to_s + ' GB'
    elsif size_in_bytes > 1000000
      return (size_in_bytes/1000000).to_s + ' MB'
    elsif size_in_bytes > 1000
      return (size_in_bytes/1000).to_s + ' KB'
    else
      return (size_in_bytes).to_s + ' B'
    end
  end

end

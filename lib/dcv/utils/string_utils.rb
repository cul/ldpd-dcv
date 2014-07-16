module Dcv::Utils::StringUtils

  def self.zero_pad_year(year)
    year = year.to_s
    is_negative = year.start_with?('-')
    year_without_sign = (is_negative ? year[1, year.length]: year)
    if year_without_sign.length < 4
      year_without_sign = year_without_sign.rjust(4, '0')
    end

    return (is_negative ? '-' : '') + year_without_sign
  end

end

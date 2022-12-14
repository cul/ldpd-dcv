module Dcv::StringHelper
  def first_sort_letter_for_string(str)
    extracted_letter = str.match(/[\p{L}&&[^\p{Lm}]]|\p{N}/).tap {|c| c if c }.to_s
    transliterated_downcase_letter = ActiveSupport::Inflector.transliterate(extracted_letter).downcase
    transliterated_downcase_letter.present? && transliterated_downcase_letter != '?' ? transliterated_downcase_letter : extracted_letter
  end

  def dirname_prefixed_with_slash(args)
    values = args[:document][args[:field]]

    values.map {|value|
      value = value.split('/data/')[1..-1].join('/data/') if !value.index('/data/').nil?
      value = '/' + value unless value.start_with?('/')

      dirname = File.dirname(value)
      dirname = '/' if dirname == '.'
      return dirname
    }
  end
end

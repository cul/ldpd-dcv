class ArchivalContext
  attr_accessor :id, :title, :bib_id, :type, :contexts, :repo_code
  ROMAN_SERIES = /Series ([clxvi]+)/i
  ROMAN_SUBSERIES = /^(Subseries\s)?([clxvi]+).([a-z0-9]+)/i
  ARABIC_SERIES = /Series ([\d]+)/i
  ARABIC_SUBSERIES = /^(Subseries\s)?([\d]+).([a-z0-9]+)/i
  ALPHABET = 'abcdefghijklmnopqrstuvwxyz'

  def initialize(json, repo_code = 'nnc-rb')
    @id = json['@id']
    @title = json['dc:title']
    json['dc:bibliographicCitation']&.tap do |citation|
      @bib_id = citation['@id'].split('/').last
      @type = 'collection'
    end
    @contexts = json['dc:coverage'] || []
    @repo_code = repo_code
  end

  def catalog_url
    "https://clio.columbia.edu/catalog/#{bib_id}" if bib_id
  end

  def finding_aid_url(series = nil, subseries = nil)
    if bib_id
      url = "https://findingaids.library.columbia.edu/ead/#{repo_code.downcase}/ldpd_#{bib_id}"
      # https://findingaids.library.columbia.edu/ead/nnc-rb/ldpd_4079747/dsc/1
      if series
        url << "/dsc/#{series}"
        if subseries
          subseries_d = subseries.downcase
          subseries = (ALPHABET.index(subseries_d) + 1) if ALPHABET.index(subseries_d) >= 0
          url << "#subseries_#{subseries}"
        end
      end
      url
    end
  end

  def titles(args = {})
    @contexts.map do |context|
      title = title_for(context, args)
      next_context = context['dc:hasPart']
      while next_context
        title << '. ' << title_for(next_context, args)
        next_context = next_context['dc:hasPart']
      end
      title
    end
  end

  def title_for(context, args = {})
    link_titles = args.fetch(:link, true)
    if context['dc:bibliographicCitation']
      link_titles ? "<a href=\"#{finding_aid_url}\">#{context['dc:title']}</a>" : context['dc:title'].dup
    elsif 'series'.casecmp?(context['dc:type'])
      title = context['dc:title'].dup
      if link_titles
        if (match = ROMAN_SERIES.match(title))
          series = ArchivalContext.roman_to_arabic(match[1].upcase)
          title = "<a href=\"#{finding_aid_url(series)}\">#{context['dc:title']}</a>"
        end
        if (match = ARABIC_SERIES.match(title))
          series =match[1].to_i
          title = "<a href=\"#{finding_aid_url(series)}\">#{context['dc:title']}</a>"
        end
      end
      title
    elsif 'subseries'.casecmp?(context['dc:type'])
      title = context['dc:title'].dup
      if link_titles
        if (match = ROMAN_SUBSERIES.match(title))
          series = ArchivalContext.roman_to_arabic(match[2].upcase)
          subseries = match[3]
          title = "<a href=\"#{finding_aid_url(series, subseries)}\">#{context['dc:title']}</a>"
        end
        if (match = ARABIC_SUBSERIES.match(title))
          series = match[2].to_i
          subseries = match[3]
          title = "<a href=\"#{finding_aid_url(series, subseries)}\">#{context['dc:title']}</a>"
        end
      end
      title
    else
      context['dc:title'].dup
    end
  end

  def self.from_json(src)
    self.new(JSON.parse(src))
  end

  def self.roman_to_arabic(roman)
    arabic = 0
    while roman[-1] && roman[-1] == 'I'
      arabic += 1
      roman = roman.slice(0..-2)
    end
    while roman[-1] && roman[-1] == 'V'
      arabic += 5
      roman = roman.slice(0..-2)
    end
    while roman[-1] && roman[-1] =~ /[IX]/
      arabic -= 1 if roman[-1] == 'I'
      arabic += 10 if roman[-1] == 'X'
      roman = roman.slice(0..-2)
    end
    while roman[-1] && roman[-1] =~ /[LIX]/
      arabic -= 1 if roman[-1] == 'I'
      arabic -= 10 if roman[-1] == 'X'
      arabic += 50 if roman[-1] == 'L'
      roman = roman.slice(0..-2)
    end
    while roman[-1] && roman[-1] =~ /[CLIX]/
      arabic -= 1 if roman[-1] == 'I'
      arabic -= 10 if roman[-1] == 'X'
      arabic -= 50 if roman[-1] == 'L'
      arabic += 100 if roman[-1] == 'C'
      roman = roman.slice(0..-2)
    end

    arabic
  end
end
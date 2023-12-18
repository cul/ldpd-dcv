class Dcv::Solr::DocumentAdapter::XacmlXml
  module Fields
    include Dcv::AccessLevels # useful constants

    FUNCTION_EMBARGO = "urn:oasis:names:tc:xacml:1.0:function:date-greater-than-or-equal".freeze
    FUNCTION_ONE_STRING_MATCH = "urn:oasis:names:tc:xacml:1.0:function:string-at-least-one-member-of".freeze
    FUNCTION_ONE_URI_MATCH = "urn:oasis:names:tc:xacml:1.0:function:anyURI-at-least-one-member-of".freeze

    TYPE_DATE = "http://www.w3.org/2001/XMLSchema#date".freeze
    TYPE_STRING = "http://www.w3.org/2001/XMLSchema#string".freeze
    TYPE_URI = "http://www.w3.org/2001/XMLSchema#anyURI".freeze

    ATTRIBUTE_AFFILIATION = "http://www.ja-sig.org/products/cas/affiliation".freeze
    ATTRIBUTE_API_CONTEXT = "urn:library.columbia.edu:names:api-context".freeze

    VALUE_DENY = "Deny".freeze
    VALUE_RANDOM_CONTEXT = "urn:library.columbia.edu:names:api-context:random".freeze

    def policy
      ng_xml.xpath('/xacml:Policy', XACML_NS).first
    end

    def access_levels
      xacml&.xpath('./xacml:Rule/xacml:Description', XACML_NS).map(&:text)
    end

    def permissions_indicated?
      permissions&.length > 0
    end

    def permissions
      xacml&.xpath('./xacml:Rule[@Effect=\'Permit\']/xacml:Condition', XACML_NS)
    end

    def prohibitions
      xacml&.xpath('./xacml:Rule[@Effect=\'Deny\']/xacml:Condition', XACML_NS)
    end

    def permit_affiliations
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_AFFILIATION)
          if condition['FunctionId'].eql?(FUNCTION_ONE_STRING_MATCH)
            condition.xpath(".//xacml:AttributeValue[@DataType='#{TYPE_STRING}']", XACML_NS).text
          end
        end
      end.compact
    end

    def permit_locations
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_ONSITE)
          if condition['FunctionId'].eql?(FUNCTION_ONE_URI_MATCH)
            condition.xpath(".//xacml:AttributeValue[@DataType='#{TYPE_URI}']", XACML_NS).text
          end
        end
      end.compact
    end

    def permit_after_date
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_EMBARGO)
          if condition['FunctionId'].eql?(FUNCTION_EMBARGO)
            release_date = condition.xpath("./xacml:AttributeValue[@DataType='#{TYPE_DATE}']", XACML_NS).text
            date_to_datetime_string(release_date)
          end
        end
      end.compact.first
    end

    def suppress_random?
      prohibitions&.each do |condition|
        if condition['FunctionId'].eql?(FUNCTION_ONE_URI_MATCH)
          attr_value = condition.xpath(".//xacml:AttributeValue[@DataType='#{TYPE_URI}']", XACML_NS).text
          return true if attr_value == VALUE_RANDOM_CONTEXT
        end
      end
      false
    end

    def date_to_datetime_string(date)
      if date =~ /^\-?\d+$/
        date = "#{release_date}-01-01"
      elsif date =~ /^\-?\d+\-\d{1,2}$/
        date = "#{date}-01"
      end
      return DateTime.iso8601(date).utc.iso8601
    rescue Date::Error
      nil
    end
  end
end
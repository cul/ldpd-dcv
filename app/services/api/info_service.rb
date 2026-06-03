module Api
  class InfoService
    Result = Data.define(
      :success?,
      :data,
      :error_message,
      :error_code,
      :status
    )

    METADATA_FIELDS = {
      title: "title_display_ssm",
      author: "primary_name_ssm",
      dateCreated: "origin_info_date_created_ssm",
      collection: "lib_collection_ssm",
      extent: "physical_description_extent_ssm"
    }.freeze

    class DuplicateIdentifierError < StandardError; end

    def initialize(item_id, asset_id)
      @item_id = item_id
      @asset_id = asset_id
    end

    def call
      documents = search_documents

      item  = find_by_identifier(documents, item_id)
      asset = find_by_identifier(documents, asset_id)

      missing_ids = []
      missing_ids << "item_id=#{item_id}" unless item
      missing_ids << "asset_id=#{asset_id}" unless asset

      return not_found_result(missing_ids) if missing_ids.any?

      success(format_metadata(item, asset))
    rescue RSolr::Error::Http => e
      failure(
        "Unable to query Solr: #{e.message}",
        "solr_error",
        :service_unavailable
      )
    end

    private

    attr_reader :item_id, :asset_id

    def repository
      @repository ||= Blacklight::Solr::Repository.new(
        CatalogController.blacklight_config
      )
    end

    def search_documents
      repository.search(
        q: "*:*",
        fq: [identifier_filter],
        rows: 2
      ).documents
    end

    def identifier_filter
      %(identifier_ssim:("#{solr_escape(item_id)}" OR "#{solr_escape(asset_id)}"))
    end

    def find_by_identifier(documents, identifier)
      matches = documents.filter do |doc|
        Array(doc["identifier_ssim"]).include?(identifier)
      end

      raise DuplicateIdentifierError, identifier if matches.many?

      matches.first
    end

    def format_metadata(item, asset)
      METADATA_FIELDS.each_with_object(
        identifier: item['id'],
        imageSourceUrl: "https://triclops.library.columbia.edu/iiif/2/standard/#{asset['id']}/full/!1280,1280/0/default.jpg"
      ) do |(key, solr_field), hash|
        hash[key] = extract_first_value(item, solr_field)
      end
    end

    def extract_first_value(item, key)
      item.fetch(key, []).first.presence || ""
    end

    def solr_escape(id)
      RSolr.solr_escape(id)
    end

    def success(data)
      Result.new(
        success?: true,
        data: data,
        error_message: nil,
        error_code: nil,
        status: :ok
      )
    end

    def failure(message, code, status)
      Result.new(
        success?: false,
        data: nil,
        error_message: message,
        error_code: code,
        status: status
      )
    end

    def not_found_result(missing_ids)
    failure(
        "Solr document(s) not found for identifier(s): #{missing_ids.join(', ')}",
        "not_found",
        :not_found
    )
    end

end
end
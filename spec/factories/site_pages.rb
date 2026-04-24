# frozen_string_literal: true

# Should supply an id!
FactoryBot.define do
  factory :site_page do
    slug { 'dlc_site_page' }
    title { 'DLC Site Page' }
    columns { 1 }

    factory :site_page_with_text_blocks do
      after(:create) do |site_page|
        create(:site_text_block, site_page_id: site_page.id)
      end
    end
  end
end
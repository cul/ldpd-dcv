# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    title { 'DLC Site' }
    persistent_url   { 'https://example.com/catalog/persistent_url' }
    restricted { false }
    layout { 'catalog' }
    palette { 'monochromeDark'}
    search_type { 'catalog' }
    image_uris { ['info:fedora/test-image:1'] }
    repository_id { 'NNC'}

    factory :site_with_links do
      after(:create) do |site|
        create(:nav_link, site_id: site.id, external: false, link: 'about', sort_label: 'About')
        create(:nav_link, site_id: site.id, external: false, link: 'funding', sort_group: '01:Project History', sort_label: 'Funding')
        create(:nav_link, site_id: site.id, external: false, link: 'contributors', sort_group: '01:Project History', sort_label: 'Contributors')
      end
    end
  end
end
# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    uid { 'tester' }
    email { 'tester@example.org' }
    is_admin   { false }
  end
end
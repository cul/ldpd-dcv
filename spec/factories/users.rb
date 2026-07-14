# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "tester#{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    is_admin   { false }
  end
end
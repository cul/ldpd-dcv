# frozen_string_literal: true

module Dcv::Footer
  class ContactComponent < ViewComponent::Base
    delegate :library_policies_url, :publications_policy_url, :terms_of_use_url, to: :helpers
    def initialize(repository_code:)
      @repository_code = repository_code
    end
    def physical_location
      t("cul.archives.physical_location.#{@repository_code}")
    end
    def contact_address
      t("cul.archives.contact_address.#{@repository_code}").join("<br>").html_safe
    end
    def publications_policy_link(label = 'Order a Reproduction')
      link_to label, publications_policy_url, class: "swatch-primary"
    end
    def terms_of_use_link(label = 'Copyright and Permissions')
      link_to label, terms_of_use_url, class: "swatch-primary"
    end
    def library_policies_link(label = 'Library Policies')
      link_to label, library_policies_url, class: "swatch-primary"
    end
    def feedback_modal_link(label = 'Suggestions & Feedback')
      link_to label, '#', data: {
        toggle: 'modal', target: '#dcvModal', 'modal-embed-func' => 'feedbackEmbedUrl', 'modal-size' => 'xl', 'modal-title' => 'Suggestions and Feedback'
      }, role: 'button', class: "swatch-primary"
    end
    def email_contact_link
      email_address = t("cul.archives.contact_email.#{@repository_code}")
      link_to email_address, "mailto:#{email_address}", class:"swatch-primary"
    end
    def site_edit_link
      helpers.site_edit_link(sep: "", class: 'swatch-primary')
    end
    def telephone_contact_link
      phone_number = t("cul.archives.contact_phone.#{@repository_code}")
      link_to phone_number, "tel:#{phone_number}", class: "swatch-primary"
    end
  end
end
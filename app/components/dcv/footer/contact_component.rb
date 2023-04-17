# frozen_string_literal: true

module Dcv::Footer
  class ContactComponent < ViewComponent::Base
    delegate :library_policies_url, :publications_policy_url, :site_edit_link, :terms_of_use_url, to: :helpers
    def publications_policy_link(label = 'Order a Reproduction')
      link_to label, publications_policy_url, class: "swatch-brand"
    end
    def terms_of_use_link(label = 'Copyright and Permissions')
      link_to label, terms_of_use_url, class: "swatch-brand"
    end
    def library_policies_link(label = 'Library Policies')
      link_to label, library_policies_url, class: "swatch-brand"
    end
    def feedback_modal_link(label = 'Suggestions & Feedback')
      link_to label, '#', data: {
        toggle: 'modal', target: '#dcvModal', 'modal-embed-func' => 'feedbackEmbedUrl', 'modal-size' => 'xl', 'modal-title' => 'Suggestions and Feedback'
      }, role: 'button', class: "swatch-brand"
    end
    def email_contact_link(repository_id)
      email_address = t("cul.archives.contact_email.#{repository_id}")
      link_to email_address, "mailto:#{email_address}", class:"swatch-brand"
    end
    def telephone_contact_link(repository_id)
      phone_number = t("cul.archives.contact_phone.#{repository_id}")
      link_to phone_number, "tel:#{phone_number}", class: "swatch-brand"
    end
  end
end
Rails.application.config.content_security_policy do |policy|
    # # Allow @vite/client to hot reload changes in development
    # policy.connect_src *policy.connect_src, "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # # Allow @vite/client to hot reload javascript changes in development
    # policy.script_src *policy.script_src, :unsafe_eval, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # # Allow @vite/client to hot reload style changes in development
    # policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?
end

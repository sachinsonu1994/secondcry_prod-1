Kassi::Application.configure do

  str_to_lowercase_sym = ->(v) {
    if v.nil? || v.is_a?(Symbol)
      v
    else
      v.downcase.to_sym
    end
  }

  Config = EntityUtils.define_builder(
    [:asset_host, :string, :optional],
    [:eager_load, :bool, :mandatory, :str_to_bool],
    [:serve_static_files, :bool, :optional, :str_to_bool],
    [:log_level, transform_with: str_to_lowercase_sym, one_of: [:debug, :info, :warn, :error]]
  )

  m_config = Maybe(Config.call(APP_CONFIG.to_h))

  m_config[:asset_host].each { |asset_host|
    config.action_controller.asset_host = asset_host
  }

  m_config[:eager_load].each { |eager_load|
    config.eager_load = eager_load
  }

  m_config[:serve_static_files].each { |serve_static_files|
    config.serve_static_files = serve_static_files
  }

  m_config[:log_level].each { |log_level|
    config.log_level = log_level
  }

  # PayU configuration
  PAYU_KEY = APP_CONFIG.payu_key
  PAYU_SALT = APP_CONFIG.payu_salt
  PAYU_URL = APP_CONFIG.payu_url
  SHIPYARRI_USERNAME = APP_CONFIG.shipyarri_username
  SHIPYARRI_CLIENTID = APP_CONFIG.shipyarri_clientid
  SHIPYARRI_PARENTID = APP_CONFIG.shipyarri_parentid
end

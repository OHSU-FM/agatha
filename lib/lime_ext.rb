module LimeExt
  mattr_accessor :table_prefix
  mattr_accessor :schema

  @@table_prefix = "lime"
  if Rails.env == "test"
    @@schema = "transform"
  else
    @@schema = "public"
  end

  class Application < Rails::Application
  end
end

require "lime_ext/errors"
require "lime_ext/response_loaders"
require "lime_ext/lime_stat"
require "lime_ext/models/poly_table_model"
require "lime_ext/models/lime_tokens"
require "lime_ext/models/lime_data"
require "lime_ext/models/filter_manager"
require "lime_ext/models/virtual_survey"
require "lime_ext/limesurvey_rc/api"
require "lime_ext/limesurvey_rc/configuration"

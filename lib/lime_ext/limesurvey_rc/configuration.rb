module LimeExt
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield config
  end

  def self.credentials
    return self.config.limesurvey_username, self.config.limesurvey_password
  end

  class Configuration
    attr_accessor :limesurvey_username
    attr_accessor :limesurvey_password
    attr_accessor :service_url
  end
end

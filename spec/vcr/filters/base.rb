class VCR::Filters::Base
  def self.detect(&block)
    @detection = block
  end

  def self.filter(&block)
    @filter = block
  end

  def initialize(&detect, &clean)
    VCR.configuration.before_record do | interaction, cassette |
      detect.yield
    end
  end
end
class Iiif::Range
  attr_reader :prefix, :branches, :canvases

  def initialize(prefix = nil)
    @prefix = prefix
    @branches = []
    @canvases = []
  end

  def to_h
  end

  def branch!
    branch = (branches.length + 1).to_s
    branch = "#{prefix}.#{branch}" unless prefix.blank?
    branches << Range.new(branch)
    branches[-1]
  end
end
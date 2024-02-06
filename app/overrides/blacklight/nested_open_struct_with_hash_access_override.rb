class Blacklight::NestedOpenStructWithHashAccess
  def self.get_default_proc(cmethod)
    proc do |hash, key|
      hash[key] = cmethod.call(key: key)
    end
  end

  private

  def set_default_proc!
    self.default_proc = Blacklight::NestedOpenStructWithHashAccess.get_default_proc(nested_class.method(:new))
  end
end

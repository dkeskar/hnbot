module ValidProperty
  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods
    # database has column with name valid it not so good because
    # ActiveRecord has a method with name valid?
    # this is patch but would be better to rename column
    def instance_method_already_implemented?(method_name)
      return true if method_name.to_s == 'valid?'
      super
    end
  end

  def invalid!
    update_attribute :valid, false
    self
  end
end

class DynamicVariable
  attr_accessor :default_variable
  
  def initialize(*pairs, &block)
    self.default_variable = :value
    @bindings = []
    if block_given?
      with(*pairs, &block)
    else
      push_pairs(pairs) unless pairs.empty?
    end
  end
  
  def push(variable, value)
    pair = [variable, value]
    @bindings << pair
    pair
  end
  
  def pop(variable)
    index = rindex(variable)
    @bindings.slice!(index)[1] if index
  end
  
  ##
  # with {}
  #   varible defaults to default_variable
  #   value defaults to nil
  #
  # with(value) { block }
  #   variable defaults to default_variable
  #
  # with(variable, value) { block }
  #
  # with(variable_1, value_1, ..., variable_n_1, value_n_1, value_n) { block }
  #   variable_n defaults to default_variable
  #
  # with(variable_1, value_1, ..., variable_n, value_n) { block }
  #
  def with(*pairs)
    pairs = [nil] if pairs.empty?
    begin
      push_pairs(pairs)
      yield(self)
    ensure
      pop_pairs(pairs)
    end
  end
  
  def [](variable)
    find_binding(variable)[1]
  end
  
  def []=(variable, value)
    find_binding(variable)[1] = value
  end
  
  def method_missing(variable, *args)    
    if args.empty?
      value = self[variable]
      instance_eval %Q{def #{variable}; self[:#{variable}] end}
    else
      writer = variable
      unless args.size == 1 and writer.to_s =~ /(.*)=/
        raise NoMethodError,
          "undefined method `#{writer}' for #{self.inspect}"
      end
      variable = $1.to_sym
      self[variable] = args[0]
      instance_eval %Q{def #{writer}(v); self[:#{variable}] = v end}
    end
    value
  end
  
  def variables
    variables = {}
    @bindings.each{|variable, value| variables[variable] = value}
    variables
  end
  
  def variables=(variables)
    variables.each{|variable, value| self[variable] = value}
  end
  
  def bindings(variable = (un = true))
    if un
      @bindings.map{|pair| pair.clone}
    else
      @bindings.select{|var, value| var == variable}.map!{|var, value| value}
    end
  end
  
  def bindings=(bindings)
    set_bindings(bindings)
  end
  
  def set_bindings(variable, bindings = (un = true))
    if un
      bindings = variable
      @bindings = bindings.map do |pair|
        unless pair.is_a? Array and pair.size == 2
          raise ArgumentError,
            "expected [variable, value] pair, got #{pair.inspect}"
        end
        pair.clone
      end
    else
      unless bindings.is_a? Array
        raise ArgumentError,
          "expected bindings to be Array, got a #{bindings.class}"
      end
      index = 0
      old_bindings = @bindings
      @bindings = []
      old_bindings.each do |var, value|
        if var == variable
          unless index < bindings.size
            next
          end
          value = bindings[index]
          index += 1
        end
        push(var, value)
      end
      while index < bindings.size
        value = bindings[index]
        push(variable, value)
        index += 1
      end
    end
    bindings
  end
  
  module Mixin
    class MixedDynamicVariable < DynamicVariable
      def initialize(mix)
        super()
        @mix = mix
      end
      
      def push(variable, value)
        old_value = @mix.send(variable)
        begin
          pair = begin
            find_binding(variable)
          rescue ArgumentError
            super
          end
          pair[1] = old_value
        
          @mix.send(variable.to_s+"=", value)
          super
        rescue Exception
          @bindings.pop
          raise
        end
      end
      
      def pop(variable)
        value = super
        begin
          old_value = find_binding(variable)[1]
        rescue ArgumentError
          return value
        end
        @mix.send(variable.to_s+"=", old_value)
        value
      ensure
        if @bindings.count{|var, value| var == variable} == 1
          super
        end
      end
      
      def [](variable)
        find_binding(variable)[1] = @mix.send(variable)
      end
      
      def []=(variable, value)
        @mix.send(variable.to_s+"=", super)
      end
      
      alias original_variables variables
      private :original_variables
      
      def variables
        variables = super
        variables.each_key do |variable|
          variables[variable] = self[variable]
        end
      end
      
      def bindings(*args)
        variables
        super
      end
      
      def set_bindings(*args)
        bindings = super
        self.variables = original_variables
        bindings
      end
    end
    
    def dynamic_variable
      @dynamic_variable_mixin__dynamic_variable ||=
        MixedDynamicVariable.new(self)
    end
    
    def with(*pairs, &block)
      dynamic_variable.with(*pairs, &block)
    end
  end
  
private
  
  def find_binding(variable)
    index = rindex(variable)
    unless index
      raise ArgumentError, "unbound variable #{variable.inspect}"
    end
    @bindings[index]
  end
  
  def rindex(variable)
    @bindings.rindex{|pair| pair[0] == variable}
  end
  
  def push_pairs(pairs)
    pairs.insert(-2, default_variable) if pairs.size.odd?
    each_pair(pairs) {|variable, value| push(variable, value)}
  end
  
  def pop_pairs(pairs)
    each_pair(pairs) {|variable, value| pop(variable)}
  end
  
  def each_pair(array)
    pair_ready = false
    head = nil
    array.each do |v|
      if pair_ready
        yield(head, v)
      else
        head = v
      end
      pair_ready = !pair_ready
    end
  end
end
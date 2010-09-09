class DynamicVariable
  @@un = Object.new
  
  def initialize(*pairs, &block)
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
  #   varible defaults to :value
  #   value defaults to nil
  #
  # with(value) { block }
  #   variable defaults to :value
  #
  # with(variable, value) { block }
  #
  # with(variable_1, value_1, ..., variable_n_1, value_n_1, value_n) { block }
  #   variable_n defaults to :value
  #
  # with(variable_1, value_1, ..., variable_n, value_n) { block }
  #
  def with(*pairs)
    pairs = [nil] if pairs.empty?
    push_pairs(pairs)
    begin
      yield(self)
    ensure
      pop_pairs(pairs)
    end
  end
  
  def with_module
    this = self
    mod = Module.new
    mod.send(:define_method, :with) do |*args, &block|
      this.with(*args, &block)
    end
    mod
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
        raise NoMethodError, "undefined method `#{writer}' for #{self.inspect}"
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
  
  def bindings(variable = @@un)
    if variable == @@un
      @bindings.map{|pair| pair.clone}
    else
      @bindings.select{|var, value| var == variable}.map!{|var, value| value}
    end
  end
  
  def bindings=(bindings)
    set_bindings(bindings)
  end
  
  def set_bindings(variable, bindings = @@un)
    if bindings == @@un
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
    pairs.insert(-2, :value) if pairs.size.odd?
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
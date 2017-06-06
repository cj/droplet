require "droplet/version"

# operations made simple
class Droplet
  # uh oh, error class raised by Droplet
  class DropletError < StandardError
    attr_reader :type, :message, :result

    def initialize(type=nil, message=nil, result=nil)
      @type    = type
      @message = message
      @result  = result

      super("#{message}: #{type}")
    end
  end

  # A thread safe cache class, offering only #[] and #[]= methods,
  # each protected by a mutex.
  class DropletCache
    # Create a new thread safe cache.
    def initialize(hash={})
      @mutex = Mutex.new
      @hash = hash
    end

    # Make getting value from underlying hash thread safe.
    def [](key)
      @mutex.synchronize { @hash[key] }
    end

    # Make setting value in underlying hash thread safe.
    def []=(key, value)
      @mutex.synchronize { @hash[key] = value }
    end
  end

  class << self
    def call(*params)
      new(*params).run
    end

    def step(name, klass=nil, &block)
      store[:steps] << [name, klass, block]
    end

    def error(type, message, result)
      raise DropletError.new(type, message, result)
    end

    def store
      @store ||= DropletCache.new(steps: [])
    end
  end

  def initialize(*params)
    store[:params] = params
  end

  def run
    steps.each do |name, klass, block|
      @klass = klass
      @step  = name

      run_step(name, params, &block) || break
    end

    result
  end

  def run_step(name, params, &block)
    @result = begin
      if block
        instance_exec(*(result || params), &block)
      else
        send("#{name}_step", *(result || params))
      end
    end
  end

  protected

  attr_accessor :result, :step, :klass

  def store
    @store ||= DropletCache.new
  end

  def params
    store[:params]
  end

  def step_error(result)
    error(step, "Step Error", result)
  end

  def error(type, message, result)
    klass = self.class

    klass.error(type, message, result)

    @result = nil
  end

  def class_store
    self.class.store
  end

  def steps
    class_store[:steps]
  end
end

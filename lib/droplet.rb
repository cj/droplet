require "droplet/version"

# operations made simple
class Droplet
  # uh oh, error class raised by Droplet
  class DropletError < StandardError
    attr_reader :type, :message, :result

    def initialize(type=nil, message=nil, result=nil)
      @type    = type
      @message = "#{message}: <#{type}> #{result}"
      @result  = result
    end
  end

  # A thread safe cache class, offering only #[] and #[]= methods,
  # each protected by a mutex.
  class DropletCache
    # Create a new thread safe cache.
    def initialize(hash={})
      @mutex = Mutex.new
      @hash  = hash
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
    def inherited(subclass)
      super

      store[:failures].each {|failure| subclass.store[:failures].push(failure.dup) }
      store[:steps].each    {|step| subclass.store[:steps] << step.dup }
    end

    def call(*params)
      new(*params).run
    end

    def step(name, klass=nil, &block)
      store[:steps] << [name, klass, block]
    end

    def failure(&block)
      store[:failures].push(block)
    end

    def store
      @_store ||= DropletCache.new(steps: [], failures: [])
    end
  end

  def initialize(*params)
    store[:params] = params
  end

  def run
    self.class.store[:steps].each do |name, klass, block|
      @_step = {name: name, class: klass}

      run_step(name, params, &block) || break
    end

    @_result
  end

  def run_step(name, params, &block)
    @_result = begin
      if block
        instance_exec(*(@_result || params), &block)
      else
        send("#{name}_step", *(@_result || params))
      end
    end
  end

  protected

  def store
    @_store ||= DropletCache.new
  end

  def params
    store[:params]
  end

  def step
    @_step || {}
  end

  def step_error(result)
    error(@_step[:name], "Step Error", result)
  end

  def error(type, message, result)
    raise DropletError.new(type, message, result)
  ensure
    self.class.store[:failures].each do |failure|
      instance_exec(&failure)
    end

    @_result = nil
  end
end

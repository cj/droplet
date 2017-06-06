require "droplet/version"

class Droplet
  class DropletError < StandardError; end

  # A thread safe cache class, offering only #[] and #[]= methods,
  # each protected by a mutex.
  class DropletCache
    # Create a new thread safe cache.
    def initialize(hash = {})
      @mutex = Mutex.new
      @hash = hash
    end

    # Make getting value from underlying hash thread safe.
    def [](key)
      @mutex.synchronize{@hash[key]}
    end

    # Make setting value in underlying hash thread safe.
    def []=(key, value)
      @mutex.synchronize{@hash[key] = value}
    end
  end

  class << self
    def call(*params)
      new(*params).run
    end

    def step(name, klass = nil, &block)
      store[:steps] << [name, klass, block]
    end

    def store
      @store ||= DropletCache.new({
        steps: []
      })
    end
  end

  def initialize(*params)
    store[:params] = params
  end

  def run
    steps.each do |name, klass, block|
      @klass = klass

      unless run_step(name, params, &block)
        break
      end
    end

    @result
  end

  def run_step(name, params, &block)
    @result = begin
      if block
        instance_exec(*(@result || params), &block)
      else
        public_send("#{name}_step", *(@result || params))
      end
    rescue DropletError => message
      error(name, message)
    end
  end

  protected

  def store
    @store ||= DropletCache.new
  end

  def params
    @store[:params]
  end

  def error(type, message)

  end

  def class_store
    self.class.store
  end

  def steps
    class_store[:steps]
  end
end

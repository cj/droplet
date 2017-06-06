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

      droplet[:splashes].each {|splash| subclass.droplet[:splashes].push(splash.dup) }
      droplet[:drips].each    {|drip| subclass.droplet[:drips] << drip.dup }
    end

    def call(*params)
      new(*params).run
    end

    def drip(name, klass=nil, &block)
      droplet[:drips] << [name, klass, block]
    end
    alias step drip

    def splash(&block)
      droplet[:splashes].push(block)
    end
    alias failure splash

    def droplet
      @_droplet ||= DropletCache.new(drips: [], splashes: [])
    end
    alias store droplet
  end

  def initialize(*params)
    droplet[:params] = params
  end

  def run
    self.class.droplet[:drips].each do |name, klass, block|
      @_drip = {name: name, class: klass}

      run_drip(name, params, &block) || break
    end

    @_result
  end

  def run_drip(name, params, &block)
    @_result = begin
      if block
        instance_exec(*(@_result || params), &block)
      else
        method_name = if self.class.private_instance_methods.include?(:"#{name}_step")
          "#{name}_step"
        else
          "#{name}_drip"
        end

        send(method_name, *(@_result || params))
      end
    end
  end

  protected

  def droplet
    @_droplet ||= DropletCache.new
  end
  alias store droplet

  def params
    droplet[:params]
  end

  def drip
    @_drip || {}
  end
  alias step drip

  def splash(result)
    error(@_drip[:name], "Drip Error", result)
  end
  alias step_error splash

  def error(type, message, result)
    raise DropletError.new(type, message, result)
  ensure
    self.class.droplet[:splashes].each do |splash|
      instance_exec(&splash)
    end

    @_result = nil
  end
end

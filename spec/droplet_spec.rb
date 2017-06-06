require "spec_helper"
require "dry-validation"

FooSchema = Dry::Validation.Schema do
  required(:bar).filled
end

UserSchema = Dry::Validation.Schema do
  required(:first_name).filled
  required(:last_name).filled
end

class CustomDroplet < Droplet
  def validation_step(params)
    dry_validation = @klass.(params)
    errors = dry_validation.errors

    if errors.any?
      raise DropletError, errors
    else
      [dry_validation]
    end
  end
end

class FooDroplet < Droplet
  step(:validation) do |foo = {}|
    dry_foo = FooSchema.(foo)
    errors  = dry_foo.errors

    if errors.any?
      raise DropletError, errors
    end
  end
end

class UserDroplet < CustomDroplet
  step(:validation, UserSchema)
  step(:format)

  def format_step(dry_user)
    user = dry_user.to_hash
    user[:full_name] = "#{user[:first_name].capitalize} #{user[:last_name].capitalize}"
    user
  end
end

describe Droplet do
  it "should throw validation error" do
    foo_droplet = FooDroplet.new.run
  end

  describe "custom droplet" do
    it "should have full_name" do
      user_droplet = UserDroplet.({ first_name: 'foo', last_name: 'bar' })
      user_droplet[:full_name].must_equal "Foo Bar"
    end
  end
end

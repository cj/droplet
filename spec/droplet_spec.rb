require "./spec/spec_helper"
require "dry-validation"

FooSchema = Dry::Validation.Schema do
  required(:bar).filled
end

UserSchema = Dry::Validation.Schema do
  required(:first_name).filled
  required(:last_name).filled
end

# Example of a custom Droplet
class CustomDroplet < Droplet
  def validation_step(params)
    dry_validation = klass.(params)
    errors = dry_validation.errors

    errors.any? ? step_error(errors) : [dry_validation]
  end
end

# Foo Droplet
class FooDroplet < Droplet
  step(:validation) do |foo={}|
    dry_foo = FooSchema.(foo)
    errors  = dry_foo.errors

    step_error(errors) if errors.any?
  end
end

# User Droplet
class UserDroplet < CustomDroplet
  step(:validation, UserSchema)
  step(:format)

  private

  def format_step(dry_user)
    user = dry_user.to_hash
    user[:full_name] = "#{user[:first_name].capitalize} #{user[:last_name].capitalize}"
    user
  end
end

describe Droplet do
  it "should throw validation error" do
    error = -> { FooDroplet.new.run }.must_raise Droplet::DropletError
    error.type.must_equal :validation
    error.message.must_equal "Step Error"
    error.result[:bar].must_include "is missing"
  end

  describe "CustomDroplet" do
    context "#result" do
      subject { UserDroplet.(first_name: "foo", last_name: "bar") }

      it { subject[:full_name].must_equal "Foo Bar" }
    end
  end
end

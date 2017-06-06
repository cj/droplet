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
  splash do
    puts "CustomDroplet failed"
  end

  private

  def validation_drip(params={})
    dry_validation = drip[:class].(params)

    if (errors = dry_validation.errors) && errors.any?
      splash(errors)
    else
      [dry_validation]
    end
  end
end

# Foo Droplet
class FooDroplet < Droplet
  drip(:validation) do |foo={}|
    dry_foo = FooSchema.(foo)

    if (errors = dry_foo.errors) && errors.any?
      splash(errors)
    end
  end
end

# User Droplet
class UserDroplet < CustomDroplet
  drip(:validation, UserSchema)
  drip(:format)
  splash do
    puts "UserDroplet failed"
  end

  private

  def format_drip(dry_user)
    user = dry_user.to_hash
    user[:full_name] = "#{user[:first_name].capitalize} #{user[:last_name].capitalize}"
    user
  end
end

describe Droplet do
  it "should throw validation error" do
    error = -> { FooDroplet.new.run }.must_raise Droplet::DropletError
    error.type.must_equal :validation
    error.message.must_match(/Drip Error/)
    error.result[:bar].must_include "is missing"
  end

  describe "CustomDroplet" do
    context "#result" do
      subject { UserDroplet.(first_name: "foo", last_name: "bar") }

      it { subject[:full_name].must_equal "Foo Bar" }
    end

    it "should capture splashs" do
      splash = -> { begin; UserDroplet.(); rescue; end; }
      splash.must_output(/UserDroplet failed/)
      splash.must_output(/CustomDroplet failed/)
    end
  end
end

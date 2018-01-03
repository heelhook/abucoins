require 'spec_helper'

describe Abucoins::API do
  subject(:ruby_gem) { Abucoins::API.new }

  describe ".new" do
    it "makes a new instance" do
      expect(ruby_gem).to be_a Abucoins::API
    end
  end
end

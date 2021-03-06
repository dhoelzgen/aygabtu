require 'rails_application_helper'

require 'aygabtu/rspec'

require 'support/aygabtu_sees_routes'

describe "anatonomy of an aygabtu example" do
  extend AygabtuSeesRoutes

  include Aygabtu::RSpec.example_group_module

  aygabtu_sees_routes do
    get 'bogus/:segment1/:segment2', to: 'bogus#action'
  end

  context "contains a generated example" do
    action(:action) do
      let(:spy) { double "assertion spy" }

      before do
        # HERE are the assertions
        #
        # We could depend upon aygabtu internals to make three examples out of this,
        # but probably it is better to keep the excercised code close to "production" code
        # sacrifying test readibility and RSpec idioms a bit.

        # for dynamic segments, the corresponding method is called
        expect(spy).to receive(:dynamic_segment) { 'foo' }

        # the aygabtu example uses capybara-rspec in this way:
        expect(spy).to receive(:visit).with('/bogus/fixed/foo')

        # then, this is how asserting is triggered
        expect(spy).to receive(:aygabtu_assertions)
      end

      def visit(argument)
        spy.visit(argument)
      end

      def aygabtu_assertions
        spy.aygabtu_assertions
      end

      def dynamic_segment
        spy.dynamic_segment
      end

      visit_with(segment1: 'fixed', segment2: :dynamic_segment)
    end
  end

  remaining do
    # sanity check.
    it "has covered route and thus created an example" do
      expect(self.class.aygabtu_matching_routes).to be_empty
    end
  end
end



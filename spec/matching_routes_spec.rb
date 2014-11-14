require 'rails_application_helper'

require 'aygabtu/rspec'

require 'json'

require 'support/identifies_routes'

RSpec.configure do |rspec|
  rspec.register_ordering(:honors_final) do |items|
    final, nonfinal = items.partition { |item| item.metadata[:final] }
    [*nonfinal.shuffle, *final]
  end
end

Rails.application.routes.draw do
  extend IdentifiesRoutes

  namespace "not_remaining" do
    get 'bogus', identified_by(:controller_route).merge(to: 'controller_a#bogus')

    namespace "namespace" do
      get 'bogus', identified_by(:namespaced_controller_route).merge(to: 'controller_a#bogus')
    end

    get 'bogus', identified_by(:action_route).merge(to: 'bogus#some_action')

    get ':segment', identified_by(:with_segment).merge(to: 'bogus#bogus')
    get '*glob', identified_by(:with_glob).merge(to: 'bogus#bogus')

    get 'implicitly_named', identified_by(:implicitly_named).merge(to: 'bogus#bogus')
    get 'bogus', identified_by(:explicitly_named).merge(to: 'bogus#bogus', as: :explicitly_named)
  end

  get 'bogus', identified_by(:remaining_route).merge(to: 'bogus#bogus')
end

describe "aygabtu scopes and their matching routes", bundled: true, order: :honors_final do
  # make routes_for_scope a hash shared by all example groups below
  def self.routes_for_scope
    return superclass.routes_for_scope if superclass.respond_to?(:routes_for_scope)
    @routes_for_scope ||= {}
  end

  context "wrapping aygabtu declarations for cleanliness only here" do
    include Aygabtu::RSpec.example_group_module

    # routes matched by aygabtu in different contexts are collected here.

    namespace :not_remaining do
      # namespacing all routes (above) and all aygabtu scopings here except for
      # the 'remaining' case makes all these cases read as if both the remaining route
      # and this namespacing were not there.
      # So ignore them on first reading (except for the fact the route name includes this namespace).
      # This trick simplifies coexistence with the 'remaining' case. See bottom of this block.

      controller(:controller_a) do
        routes_for_scope['controller controller_a'] = aygabtu_matching_routes
      end

      controller('namespace/controller_a') do
        routes_for_scope['controller namespace/controller_a'] = aygabtu_matching_routes
      end

      action(:some_action) do
        routes_for_scope['action some_action'] = aygabtu_matching_routes
      end

      namespace('namespace') do
        routes_for_scope['namespace namespace'] = aygabtu_matching_routes
      end

      named(:not_remaining_implicitly_named) do
        routes_for_scope['named implicitly_named'] = aygabtu_matching_routes
      end

      named(:not_remaining_explicitly_named) do
        routes_for_scope['named explicitly_named'] = aygabtu_matching_routes
      end

      requiring(:segment) do
        routes_for_scope['requiring segment'] = aygabtu_matching_routes
      end

      requiring(:glob) do
        routes_for_scope['requiring glob'] = aygabtu_matching_routes
      end

      requiring_anything(true) do
        routes_for_scope['requiring_anything true'] = aygabtu_matching_routes
      end

      requiring_anything(false) do
        routes_for_scope['requiring_anything false'] = aygabtu_matching_routes
      end

      ## MUST BE AT THE BOTTOM
      ignore "this makes all routes except the 'remaining' one remaining for aygabtu"
    end

    remaining do
      routes_for_scope['remaining'] = aygabtu_matching_routes
    end
  end

  include IdentifiesRoutes

  describe 'matching routes' do
    # use the :scope metadata to define an example group's routes
    def self.routes
      @routes ||= routes_for_scope.delete(metadata.fetch(:scope)) || raise("bad scope key?")
    end

    # make these routes available to the group's examples
    def routes
      self.class.routes
    end

    describe 'controller scoping' do
      context "scope", scope: 'controller controller_a' do
        it "matches unnamespaced controller route" do
          expect(routes).to include(be_identified_by(:controller_route))
        end

        it "matches namespaced controller route" do
          expect(routes).to include(be_identified_by(:namespaced_controller_route))
        end
      end

      context "scope", scope: 'controller namespace/controller_a' do
        it "does not match unnamespaced controller route" do
          expect(routes).not_to include(be_identified_by(:controller_route))
        end

        it "matches namespaced controller route" do
          expect(routes).to include(be_identified_by(:namespaced_controller_route))
        end
      end
    end

    describe 'action scoping' do
      context "scope", scope: 'action some_action' do
        it "matches route with given action" do
          expect(routes).to contain_exactly(be_identified_by(:action_route))
        end
      end
    end

    describe 'namespace scoping' do
      context "scope", scope: 'namespace namespace' do
        it "matches namespaced route" do
          expect(routes).to contain_exactly(be_identified_by(:namespaced_controller_route))
        end
      end
    end

    describe 'named scoping' do
      context "scope", scope: 'named implicitly_named' do
        it "matches implicitly named route" do
          expect(routes).to contain_exactly(be_identified_by(:implicitly_named))
        end
      end

      context "scope", scope: 'named explicitly_named' do
        it "matches explicitly named route" do
          expect(routes).to contain_exactly(be_identified_by(:explicitly_named))
        end
      end
    end

    describe 'requiring scoping' do
      context "scope", scope: 'requiring segment' do
        it "matches route requiring given segment" do
          expect(routes).to contain_exactly(be_identified_by(:with_segment))
        end
      end

      context "scope", scope: 'requiring glob' do
        it "matches route requiring given glob" do
          expect(routes).to contain_exactly(be_identified_by(:with_glob))
        end
      end
    end

    describe "requiring_anything scoping" do
      context "scope", scope: 'requiring_anything true' do
        it "matches route requiring any segment or glob" do
          expect(routes).to contain_exactly(
            be_identified_by(:with_segment),
            be_identified_by(:with_glob)
          )
        end
      end

      context "scope", scope: 'requiring_anything false' do
        it "matches route not requiring any segment or glob" do
          expect(routes).not_to be_empty
          expect(routes).not_to include(be_identified_by(:with_segment))
          expect(routes).not_to include(be_identified_by(:with_glob))
        end
      end
    end

    describe "remaining scoping" do
      context "scope", scope: 'remaining' do
        it "matches route not matched yet" do
          expect(routes).to contain_exactly(be_identified_by(:remaining_route))
        end
      end
    end
  end

  # this example group will be executed last, (see final metadata and declared sorting)
  describe 'test coverage', final: true do
    it "has exhausted all registered scope data" do
      # we cannot make sure this is the last example executed.
      expect(self.class.routes_for_scope).to be_empty
    end
  end

end
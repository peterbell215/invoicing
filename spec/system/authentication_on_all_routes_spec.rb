require 'rails_helper'

class FilteredRoutes
  include Singleton

  attr_reader :filtered_routes

  private

  def initialize
    @filtered_routes = Rails.application.routes.routes.map do |r|
      route = ActionDispatch::Routing::RouteWrapper.new r
      route&.verb.present? && !route.internal? && !excluded_route?(route.ast.to_s) ? route : nil
    end.compact!
  end

  def excluded_route?(path)
    EXCLUDED_ROUTE_PATTERNS.any? { |pattern| path.match?(pattern) }
  end

  # Define patterns for routes to exclude from authentication testing
  EXCLUDED_ROUTE_PATTERNS = [
    %r{^/up\(\.:format\)$},                   # Health check endpoint
    %r{^/passwords},                          # Password reset routes
    %r{^/users/:user_id/password},                   # Also password reset
    %r{^/session},                            # Session route
    %r{^/sign_in\(\.:format\)$},              # Sign in page
    %r{^/sign_out\(\.:format\)$},             # Sign out page
    %r{^/rails},                              # Active Storage, Active Mailbox, Active Conductor routes
    %r{^/cable$},                              # Action Cable endpoint
    %r{_historical_location}
  ].freeze
end

RSpec.describe "Authentication on all routes", type: :system do
  FilteredRoutes.instance.filtered_routes.each do |route|
    path = route.ast.to_s.dup
    path.gsub!(/:[a-z_]*id/, '1') # replace :id with a dummy id
    path.gsub!(/\(.:format\)/, '') # remove optional format for simplicity

    it "should redirect #{route.verb} #{path} (#{route.ast.to_s})" do
      send(route.verb.downcase, path)

      # test it does indeed redirect
      expect(response.status).to eq(302)
      expect(response.location).to include('/sign_in')

      # you could also continue further testing
      follow_redirect!
      expect(response.body).to include('Password')
    end
  end
end
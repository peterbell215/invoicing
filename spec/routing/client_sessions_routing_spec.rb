require "rails_helper"

RSpec.describe ClientSessionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/client_sessions").to route_to("client_sessions#index")
    end

    it "routes to #new" do
      expect(get: "/client_sessions/new").to route_to("client_sessions#new")
    end

    it "routes to #show" do
      expect(get: "/client_sessions/1").to route_to("client_sessions#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/client_sessions/1/edit").to route_to("client_sessions#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/client_sessions").to route_to("client_sessions#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/client_sessions/1").to route_to("client_sessions#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/client_sessions/1").to route_to("client_sessions#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/client_sessions/1").to route_to("client_sessions#destroy", id: "1")
    end
  end
end

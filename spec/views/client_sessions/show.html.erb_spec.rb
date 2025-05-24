require 'rails_helper'

RSpec.describe "client_sessions/show", type: :view do
  before(:each) do
    assign(:client_session, ClientSession.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end

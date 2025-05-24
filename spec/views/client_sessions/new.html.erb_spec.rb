require 'rails_helper'

RSpec.describe "client_sessions/new", type: :view do
  before(:each) do
    assign(:client_session, ClientSession.new())
  end

  it "renders new client_session form" do
    render

    assert_select "form[action=?][method=?]", client_sessions_path, "post" do
    end
  end
end

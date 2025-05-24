require 'rails_helper'

RSpec.describe "client_sessions/edit", type: :view do
  let(:client_session) {
    ClientSession.create!()
  }

  before(:each) do
    assign(:client_session, client_session)
  end

  it "renders the edit client_session form" do
    render

    assert_select "form[action=?][method=?]", client_session_path(client_session), "post" do
    end
  end
end

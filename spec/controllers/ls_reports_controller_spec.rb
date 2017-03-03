require "spec_helper"

describe LsReportsController do
  after :each do
    Redis.current.flushdb
  end

  it "should require authentication" do
    get :index
    assert_response :redirect
  end

  it "should set @surveys" do
    ra = create :role_aggregate, :ready
    l = ra.lime_survey
    u = create :admin

    sign_in u
    get :index
    expect(assigns["surveys"]).to include l
  end
end

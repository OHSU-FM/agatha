class LsReportsController < ApplicationController
  include LsReportsHelper
  layout "full_width_margins"
  respond_to :json, :html

  def index
    @surveys = RoleAggregate.all
  end
end

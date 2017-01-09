module Api::V1
  class BaseController < ApplicationController
    include TypedParameters::ControllerMethods
    include TokenAuthentication
    include CurrentAccountScope
    include SharedScopes
    include Pagination
  end
end

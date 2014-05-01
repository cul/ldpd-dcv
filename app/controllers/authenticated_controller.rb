class AuthenticatedController < ApplicationController
  include Dcv::Authenticated::AccessControl
end

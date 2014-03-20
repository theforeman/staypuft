module Staypuft
  class DeploymentsController < ApplicationController
    def index
    end

    def show
      @hostgroups = Hostgroup.all
    end
  end
end

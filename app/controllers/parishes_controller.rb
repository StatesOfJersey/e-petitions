class ParishesController < ApplicationController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @parishes = Parish.all

    respond_to do |format|
      format.json
    end
  end
end

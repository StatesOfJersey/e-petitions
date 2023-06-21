require 'postcode_sanitizer'
require 'csv'

class LocalPetitionsController < ApplicationController
  before_action :raise_routing_error, if: :local_petitions_disabled?
  before_action :sanitize_postcode, only: :index
  before_action :find_by_postcode, if: :postcode?, only: :index
  before_action :find_by_slug, only: [:show, :all]
  before_action :find_petitions, if: :parish?, only: :show
  before_action :find_all_petitions, if: :parish?, only: :all
  before_action :redirect_to_parish, if: :parish?, only: :index

  after_action :set_content_disposition, if: :csv_request?, only: [:show, :all]

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json
      format.csv
    end
  end

  def all
    respond_to do |format|
      format.html
      format.json
      format.csv
    end
  end

  private

  def sanitize_postcode
    @postcode = PostcodeSanitizer.call(params[:postcode])
  end

  def postcode?
    @postcode.present?
  end

  def find_by_postcode
    @parish = Parish.find_by_postcode(@postcode)
  end

  def find_by_slug
    @parish = Parish.find_by_slug!(params[:id])
  end

  def parish?
    @parish.present?
  end

  def find_petitions
    @petitions = Petition.popular_in_parish(@parish.id, 50)
  end

  def find_all_petitions
    @petitions = Petition.all_popular_in_parish(@parish.id, 50)
  end

  def redirect_to_parish
    redirect_to local_petition_url(@parish.slug)
  end

  def csv_filename
    if action_name == 'all'
      "all-popular-petitions-in-#{@parish.slug}.csv"
    else
      "open-popular-petitions-in-#{@parish.slug}.csv"
    end
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end

  def local_petitions_disabled?
    Site.disable_local_petitions?
  end
end

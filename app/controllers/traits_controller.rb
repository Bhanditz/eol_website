class TraitsController < ApplicationController
  include DataAssociations
  helper :data

  before_action :no_main_container, only: [:search, :search_results, :search_form, :show]
  before_action :build_query, only: [:search_results, :search_form]

  def search
    @query = TermQuery.new(:result_type => :taxa)
    @query.filters.build(:op => :is_any)
  end

  def search_results
    respond_to do |fmt|
      fmt.html do
        if @query.valid?
          Rails.logger.warn @query.to_s
          search_common
        else
          render "search"
        end
      end

      fmt.csv do
        if !current_user
          redirect_to new_user_session_path
        else
          if @query.valid?
            url = term_search_results_url(:term_query => tq_params)
            data = TraitBank::DataDownload.term_search(@query, current_user.id, url)

            if data.is_a?(UserDownload)
              flash[:notice] = t("user_download.created", url: user_path(current_user))
              redirect_no_format
            else
              send_data data
            end
          else
            redirect_no_format
          end
        end
      end
    end
  end

  def search_form
    render :layout => false
  end

  def show
    filter_options = if params[:obj_uri]
      {
        :op => :is_obj,
        :pred_uri => params[:uri],
        :obj_uri => params[:obj_uri]
      }
    else
      {
        :op => :is_any,
        :pred_uri => params[:uri]
      }
    end

    @query = TermQuery.new({
      :filters => [TermQueryFilter.new(filter_options)],
      :result_type => :record
    })
    search_common
  end

  private
  def tq_params
    params.require(:term_query).permit([
      :clade_id,
      :result_type,
      :filters_attributes => [
        :pred_uri,
        :obj_uri,
        :op,
        :num_val1,
        :num_val2,
        :units_uri
      ]
    ])
  end

  def build_query
    @query = TermQuery.new(tq_params)
    @query.filters.delete @query.filters[params[:remove_filter].to_i] if params[:remove_filter]
    @query.filters.build(:op => :is_any) if params[:add_filter]
    blank_predicate_filters_must_search_any
  end

  # TODO: Does this logic belong in TermQuery?
  def blank_predicate_filters_must_search_any
    @query.filters.each { |f| f.op = :is_any if f.pred_uri.blank? }
  end

  def paginate_term_search_data(data, query)
    Rails.logger.warn "&&TS Running count:"
    # @count = 1_000_000
    @count = TraitBank.term_search(query, { count: true })
    @grouped_data = Kaminari.paginate_array(data, total_count: @count).page(@page).per(@per_page)

    if query.taxa?
      @result_pages = @grouped_data.map do |datum|
        @pages[datum[:page_id]]
      end.compact

      @result_pages = PageSearchDecorator.decorate_collection(@result_pages)
    end
  end

  def permitted_filter_params(filter_params)
    filter_params.permit(
      :pred_uri,
      :uri,
      :value,
      :from_value,
      :to_value,
      :units_uri
    )
  end

  def search_common
    @page = params[:page] || 1
    @per_page = 50
    Rails.logger.warn "&&TS Running search:"
    res = TraitBank.term_search(@query, {
      :page => @page,
      :per => @per_page,
    })
    data = res[:data]
    @raw_query = res[:raw_query]
    @raw_res = res[:raw_res].to_json
    ids = data.map { |t| t[:page_id] }.uniq
    # HERE IS THE IMPORTANT DB QUERY TO LOAD PAGES:
    pages = Page.where(:id => ids).with_hierarchy
    @pages = {}

    ids.each do |id|
      page = pages.find { |p| p.id == id }
      @pages[id] = page if page
    end

    # TODO: code review here. I think we're creating a lot of cruft we don't use.
    paginate_term_search_data(data, @query)
    @is_terms_search = true
    @resources = TraitBank.resources(data)
    build_associations(data)
    render "search"
  end

  def redirect_no_format
    loc = params
    loc.delete(:format)
    # NOTE: this kind of redirect_to is deprecated and should probably changed to (but I don't want to test now)
    # redirect_to params.merge(controller: :traits, action: :search_results)
    redirect_to term_search_results_path(params)
  end
end

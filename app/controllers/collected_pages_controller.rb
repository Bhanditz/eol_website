class CollectedPagesController < ApplicationController
  layout "application"

  def new
    @collected_page = CollectedPage.new(new_page_params)
    @page = @collected_page.page
    @wants_icon = ! @collected_page.media.empty?
    @collection = Collection.new(collected_pages: [@collected_page])
    @bad_collection_ids = CollectedPage.where(page_id: @page.id).
      pluck(:collection_id)
  end

  def create
    @collected_page = CollectedPage.find_or_initialize_by(existing_collected_page_params)
    if @collected_page.update(collected_page_params)
      flash[:notice] = I18n.t(:collected_page_added_to_collection,
        name: @collected_page.collection.name,
        page: @collected_page.page.name,
        link: collection_path(@collected_page.collection))
      redirect_to @collected_page.page
    else
      # TODO: some kind of hint as to the problem, in a flash...
      render "new"
    end
  end

  private

  def collected_page_params
    params.require(:collected_page).permit(:collection_id, :page_id, collected_pages_media_attributes: [:medium_id])
  end

  def existing_collected_page_params
    params.require(:collected_page).permit(:collection_id, :page_id)
  end

  def new_page_params
    params.permit(:page_id, medium_ids: [])
  end
end
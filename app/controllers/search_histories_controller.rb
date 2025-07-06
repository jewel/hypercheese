class SearchHistoriesController < ApplicationController
  respond_to :json

  def index
    histories = SearchHistory.recent_for_user(current_user, 10)
    render json: histories.map { |h| 
      {
        id: h.id,
        query: h.query,
        result_count: h.result_count,
        searched_at: h.searched_at.iso8601
      }
    }
  end

  def create
    query = params[:query]
    result_count = params[:result_count] || 0
    
    SearchHistory.record_search(current_user, query, result_count)
    
    render json: { status: 'success' }
  end

  def destroy
    if params[:id]
      # Delete a specific search history entry
      history = SearchHistory.find(params[:id])
      
      # Only allow users to delete their own search history
      if history.user == current_user
        history.destroy
        render json: { status: 'success' }
      else
        render json: { error: 'Not authorized' }, status: 403
      end
    else
      # Delete all search history for the current user
      SearchHistory.where(user: current_user).destroy_all
      render json: { status: 'success' }
    end
  end
end
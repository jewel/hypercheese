class TagsController < ApplicationController
  def index
    # Tags are sent in "priority" order.  Higher priority tags will be the
    # first match for a partial string.
    # Aliased tags come first.
    # Then any tag ever used by a user comes next.
    # Finally, the remainder of tags 
    query = Tag.sanitize_sql_array ["
      SELECT tags.id, label, icon_item_id icon, item_count, parent_tag_id parent_id, alias, uses
      FROM tags
      LEFT OUTER JOIN tag_aliases ON tag_id = tags.id AND user_id = ?
      LEFT OUTER JOIN (
        SELECT tag_id, SUM(1) uses
        FROM item_tags
        WHERE added_by = ?
        GROUP BY 1
      ) tag_uses ON tag_uses.tag_id = tags.id
      ORDER BY alias IS NULL, uses DESC, item_count DESC
    ", current_user.id, current_user.id ]
    tags = ActiveRecord::Base.connection.select_all(query)

    render json: {
      tags: tags
    }
  end

  def create
    render status: :created, json: Tag.create(tag_params)
  end

  def destroy
    render json: tag.destroy
  end

  def update
    @tag = tag
    @tag.update(tag_params)

    new_alias = alias_params[:alias]
    new_alias = nil if new_alias == ''

    tag_alias = TagAlias.where(user: current_user, tag: @tag).first
    if tag_alias
      if !new_alias
        tag_alias.delete
      else
        tag_alias.alias = new_alias
        tag_alias.save
      end
    elsif new_alias
      TagAlias.create user: current_user, tag: @tag, alias: new_alias
    end

    render json: @tag
  end

  private

  def tag_params
    p = params.dup
    p[:tag][:icon_item_id] = p[:tag][:icon]
    p[:tag][:parent_tag_id] = p[:tag][:parent_id]
    p.require(:tag).permit(:label, :icon_item_id, :parent_tag_id)
  end

  def alias_params
    params.require(:tag).permit(:alias)
  end

  def tag
    Tag.find(params[:id])
  end
end

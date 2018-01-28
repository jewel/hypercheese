class TagsController < ApplicationController
  def index
    aliases = TagAlias.where(user: current_user).index_by &:tag_id
    # Aliased tags should come first so that they take priority when tagging.
    tags = Tag.all.order 'item_count desc'
    aliased, unaliased = tags.partition { |_| aliases[ _.id ] }
    render json: aliased + unaliased
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

    tag_alias = TagAlias.where(user: current_user, tag: @tag).first
    if tag_alias
      if alias_params[:alias] == ''
        tag_alias.delete
      else
        tag_alias.alias = alias_params[:alias]
        tag_alias.save
      end
    else
      TagAlias.create user: current_user, tag: @tag, alias: alias_params[:alias]
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

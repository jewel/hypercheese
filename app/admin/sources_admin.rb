Trestle.resource(:sources) do
  menu do
    item :sources, icon: "fa fa-star"
  end

  # Customize the table columns shown on the index view.
  #
  table do
    column :label
    column :path
    column :show_on_home
    column :user
    column :items do |source|
      source.items.count
    end
    column :last_upload do |source|
      source.items.maximum(:created_at)
    end
    actions
  end

  # Customize the form fields shown on the new/edit views.
  #
  # form do |source|
  #   text_field :name
  #
  #   row do
  #     col { datetime_field :updated_at }
  #     col { datetime_field :created_at }
  #   end
  # end

  # By default, all parameters passed to the update and create actions will be
  # permitted. If you do not have full trust in your users, you should explicitly
  # define the list of permitted parameters.
  #
  # For further information, see the Rails documentation on Strong Parameters:
  #   http://guides.rubyonrails.org/action_controller_overview.html#strong-parameters
  #
  # params do |params|
  #   params.require(:source).permit(:name, ...)
  # end
end

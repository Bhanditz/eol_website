class ContentPartners::ResourcesController < ContentPartnersController
  
  def new
    @resource = Resource.new
  end
  
  def create
    resource_params = { name: params[:resource][:name], origin_url: params[:resource][:origin_url],uploaded_url: params[:resource][:uploaded_url],
                        path: params[:resource][:path],type: params[:resource][:type],harvest_frequency: params[:resource][:harvest_frequency],
                        dataset_rights_holder: params[:resource][:dataset_rights_holder],dataset_rights_statement: params[:resource][:dataset_rights_statement], 
                        default_rights_holder: params[:resource][:default_rights_holder], default_rights_statement: params[:resource][:default_rights_statement],
                        default_license_string: params[:resource][:default_license_string], default_language_id: params[:resource][:default_language_id]}
    @resource = Resource.new(resource_params)
    debugger
    if @resource.valid?
      result = ResourceApi.add_resource?(resource_params, params[:content_partner_id])
      if result
        flash.now[:notice] = :successfuly_created_resource
        redirect_to root_url
      else
        flash.now[:notice] = :error_in_connection
        render action: 'new'
      end
    else
      render action: 'new'
    end
  end
  
  def edit
    result= ResourceApi.get_resource(params[:content_partner_id], params[:id])
    mappings = {"_paused" => "is_paused", "_approved" => "is_approved" , "_trusted" => "is_trusted" , "_autopublished" => "is_autopublished" , "_forced" => "is_forced"}
    result.keys.each { |k| result[ mappings[k] ] = result.delete(k) if mappings[k] }
    @resource = Resource.new(result)
  end
  
  def update
    resource_params = { name: params[:resource][:name], origin_url: params[:resource][:origin_url],uploaded_url: params[:resource][:uploaded_url],
                        path: params[:resource][:path],type: params[:resource][:type],harvest_frequency: params[:resource][:harvest_frequency],
                        dataset_rights_holder: params[:resource][:dataset_rights_holder],dataset_rights_statement: params[:resource][:dataset_rights_statement], 
                        default_rights_holder: params[:resource][:default_rights_holder], default_rights_statement: params[:resource][:default_rights_statement],
                        default_license_string: params[:resource][:default_license_string], default_language_id: params[:resource][:default_language_id]}
    @resource = Resource.new(resource_params)
    if @resource.valid?
      result = ResourceApi.update_resource?(resource_params, params[:content_partner_id],params[:id])
      if result
        flash.now[:notice] = :successfuly_updated_resource
        redirect_to root_url
      else
        flash.now[:notice] = :error_in_connection
        render action: 'edit'
      end
    else
      render action: 'edit'
    end
  end
  
  def show
    result = ResourceApi.get_resource(params[:content_partner_id], params[:id])
    mappings = {"_paused" => "is_paused", "_approved" => "is_approved" , "_trusted" => "is_trusted" , "_autopublished" => "is_autopublished" , "_forced" => "is_forced"}
    result.keys.each { |k| result[ mappings[k] ] = result.delete(k) if mappings[k] }
    @resource = Resource.new(result)
  end
  
end

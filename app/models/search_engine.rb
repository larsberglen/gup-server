class SearchEngine
  
  def add(data: data)
    begin
      # data can be an object or a list of objects
      solr.add(data)
    rescue RSolr::Error::Http
      # TODO
    end
  end

  def delete_from_index(ids: ids)
    # ids can be a single id or a list of ids
    solr.delete_by_id(ids)
  end

  def commit
    solr.update :data => '<commit/>'
    solr.update :data => '<optimize/>'
  end

  def clear
    solr.delete_by_query("*:*")
    solr.commit
  end

end

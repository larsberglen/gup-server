class V1::ReportsController < V1::V1Controller
  def show
    filename = params[:name]+".csv"
    csv_data = generate_report(format: "csv")
    send_data csv_data, :filename => filename, type: "test/csv", disposition: "attachment" 
  end
  
  def create
    @response['report'] = generate_report
    render_json
  end
  
  private
  def generate_report(format: "json")
    report = ReportView.all
    if params[:report]
      filters = params[:report][:filter]
      columns = params[:report][:columns]
    else
      filters = nil
      columns = nil
    end

    if filters
      if filters[:start_year].present?
        report = report.where("year >= ?", filters[:start_year])
      end

      if filters[:end_year].present?
        report = report.where("year <= ?", filters[:end_year])
      end

      if filters[:publication_types].present?
        report = report.where("publication_type_id IN (?)", filters[:publication_types])
      end

      if filters[:content_types].present?
        report = report.where("content_type IN (?)", filters[:content_types])
      end

      if filters[:faculties].present?
        report = report.where("faculty_id IN (?)", filters[:faculties])
      end
      
      if filters[:departments].present?
        report = report.where("department_id IN (?)", filters[:departments])
      end

      if filters[:persons].present?
        report = report.where("xaccount IN (?)", filters[:persons])
      end
    end

    # If columns are requested, group by all columns, and calculate
    # a sum for each group. There cannot be a situation where a column
    # should be added but not grouped (SQL doesn't work that way)
    if columns.present?
      if ReportView.columns_valid?(columns)
        column_headers = columns + ['count']
        
        select_string = columns.join(",")
        report = report.group(select_string)
        report = report.select(select_string + ",count(distinct(publication_id))")
        report = report.order(columns)
        data = report.as_json(matrix: column_headers)
      else
        error_msg(ErrorCodes::REQUEST_ERROR, "Invalid column")
        return
      end
    else
      column_headers = ['count']
      report = report.distinct
      data = [[report.count]]
    end

    column_headers = column_headers.map do |col| 
      I18n.t('reports.columns.'+col.to_s)
    end

    report_data = {
      columns: column_headers,
      data: data
    }

    if format == "csv"
      csv_data = column_headers.join("\t")+"\n"
      csv_data += data.map do |rows| 
        rows.join("\t")
      end.join("\n")
      return csv_data
    else
      return report_data
    end
  end
end

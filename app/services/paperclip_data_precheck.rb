class PaperclipDataPrecheck
  attr_accessor :attachment_name
  attr_accessor :new_attachment_name
  attr_accessor :model_class

  def self.perform(model_class, attachment_names, session)
    attachment_names.each do |attachment_name|
      session.reset_status
      checker = PaperclipDataPrecheck.new

      checker.model_class = model_class
      checker.attachment_name = attachment_name
      checker.new_attachment_name = "#{attachment_name}_new"

      checker.perform_precheck(session)
    end
  end

  def perform_precheck(session)
    records_with_attachments = model_class.where("#{attachment_file_name} is not null")
    count = records_with_attachments.count
    faulty_attachment_records
    records_with_attachments.order(updated_at: :desc).each do |record|
      break if session.check_status('performing precheck', count)

      error = check_attachment(record)
      faulty_attachment_records << { record_id: record.id, error: error } if error
    end

    Rails.logger.info("#{faulty_attachment_records.count} faulty attachments:")
    faulty_attachment_records.each { |attachment| Rails.logger.info("Record: #{attachment[:record]}, error: #{attachment[:error]}") }
  end

  private

  def check_attachment(record)
    resume_url = record.send(attachment_name).expiring_url(60)
    uri = URI.parse(resume_url)
    begin
      RadicalRetry.perform_request { uri.open.read }
    rescue RadicallyIntermittentException => e
      return e.inspect
    end
  end
end
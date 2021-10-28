# frozen_string_literal: true

module LabelPrinters
  class PrintJob < ApplicationJob
    MAX_STATUS_UPDATES = 10

    queue_as :high_priority

    discard_on(StandardError) do |job, _error|
      label_printer = job.arguments.first
      label_printer.update!(status: :error)
    end

    def perform(label_printer, payload, copy_count)
      case label_printer.type_of
      when 'fluics'
        api_client = LabelPrinters::Fluics::ApiClient.new(
          label_printer.fluics_api_key
        )

        copy_count.times do
          response = api_client.print(label_printer.fluics_lid, payload)

          status = response['status'] == 'OK' ? :ready : LabelPrinter::FLUICS_STATUS_MAP[response['printerStatus']]
          label_printer.update!(status: status)

          break if status != :ready

          # remove first matching job_id from queue (one label out of batch has been printed)
          label_printer.with_lock do
            job_ids = label_printer.current_print_job_ids
            job_ids.delete_at(job_ids.index(job_id) || job_ids.length)

            label_printer.update!(current_print_job_ids: job_ids)
          end
        end
      end

      # mark as unreachable if no final state is reached
      label_printer.update!(status: :unreachable) unless label_printer.status.in? %w(ready out_of_labels error)
    end
  end
end

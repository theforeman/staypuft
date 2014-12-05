module Actions
  module Staypuft
    module Host
      class AssertReportSuccess < Dynflow::Action

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(host_id)
          plan_self host_id: host_id
        end

        def run(event = nil)
          case event
          when Dynflow::Action::Skip
            output[:status] = true
          else
            output[:status] = assert_latest_report_success(input[:host_id])
          end
        end

        private

        def assert_latest_report_success(host_id)
          host   = ::Host.find(host_id)
          report = host.reports.order('reported_at DESC').first

          unless report
            fail(::Staypuft::Exception, "No Puppet report found for host: #{host_id}")
          end

          check_for_failures(report, host_id)
          report_change?(report)
        end

        def report_change?(report)
          report.status['applied'] > 0
        end

        def check_for_failures(report, host_id)
          if report.status['failed'] > 0
            output[:report_id] = report.id
            fail(::Staypuft::Exception, "Latest Puppet run contains failures for host: #{host_id}")
          end
        end

      end
    end
  end
end

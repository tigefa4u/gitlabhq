module LogHelpers
  # Returns a stubbed logger instance which can
  # be used as a spy. E.g.:
  #
  # spy_logger = stub_logger(logger)
  # expect(spy_logger).to have_received(:info).with(hash)
  #
  def stub_logger(logger)
    logger_spy = instance_double(logger, error: nil, info: nil)

    allow(logger).to receive(:build) { logger_spy }

    logger_spy
  end
end

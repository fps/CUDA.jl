# debug functionality

function isdebug(group, mod=CUDA)
    logger = Base.CoreLogging.current_logger_for_env(Base.CoreLogging.Debug, group, mod)
    shouldLog = logger !== nothing && Logging.shouldLog(logger, Base.CoreLogging.Debug, mod, group, 0)
    println(shouldLog)
    shouldLog
end

function httpError(status, message) {
  const err = new Error(message);
  err.status = status;
  return err;
}

/** Wraps async route handlers so thrown errors reach the error middleware. */
const ah = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { httpError, ah };

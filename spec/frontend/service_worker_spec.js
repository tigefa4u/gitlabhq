const makeServiceWorkerEnv = require('service-worker-mock');
const SERVICE_WORKER_PATH = '~/sw.js';

describe('Service worker', () => {
  beforeEach(() => {
    Object.assign(global, makeServiceWorkerEnv());
    jest.resetModules();
  });

  it('should delete old caches on activate', () => {
    require(SERVICE_WORKER_PATH);

    // Create old cache
    self.caches.open('OLD_CACHE').then(() => {
      expect(self.snapshot().caches.OLD_CACHE).toBeDefined();
    });

    // Activate and verify old cache is removed
    self.trigger('activate').then(() => {
      expect(self.snapshot().caches.OLD_CACHE).toBeUndefined();
    });
  });
});

import crypto from 'crypto';
import os from 'os';
import process from 'process';

import { setTestTimeoutOnce } from 'helpers/timeout';
import { cpuTime } from './cpu_time';

describe('cpu_time', () => {
  // Swap timers before and after, because our test harness assumes fake timers in after hooks and
  // will complain if real timers are set.
  beforeEach(() => {
    jest.useRealTimers();
  });

  afterEach(() => {
    jest.useFakeTimers();
  });

  it('measures CPU time less than real time in async code', done => {
    if (os.platform === 'win32') {
      done();
    }

    setTestTimeoutOnce(2000);
    const cpu1 = cpuTime();
    const real1 = process.uptime();
    expect(cpu1.cpu).toBe(true);
    
    setTimeout(() => {
      const deltaCPU = cpuTime().time - cpu1.time;
      const deltaReal = process.uptime() - real1;

      expect(deltaCPU).toBeLessThan(deltaReal);
      expect(deltaCPU).toBeLessThan(0.2); // Shouldn't take more than 200 ms CPU time
      expect(deltaReal).toBeGreaterThan(1);
      done();
    }, 1000);

  }, 2000);

  it('measures CPU time about the same as real time in sync code', done => {
    if (os.platform === 'win32') {
      done();
    }

    setTestTimeoutOnce(5000);
    const cpu1 = cpuTime();
    const real1 = process.uptime();
    expect(cpu1.cpu).toBe(true);

    // Do an expensive operation for at least one second
    let str = '';
    let iters = 0;
    while (process.uptime() - real1 <= 1) {
      const hash = crypto.createHash('sha256');
      hash.update(Math.random().toString());
      str += hash.digest('hex');
      iters += 1;
    }

    // Make sure that the test actually did do work
    expect(str.length).toBe(256 * iters / 4); // 256 bits * iterations / 4 bits per hex char

    const deltaCPU = cpuTime().time - cpu1.time;
    const deltaReal = process.uptime() - real1;
    expect(deltaCPU).toBeLessThan(1);
    expect(deltaCPU).toBeGreaterThan(0.1);
    expect(deltaReal).toBeGreaterThan(deltaCPU);

    done();
  }, 5000);
});

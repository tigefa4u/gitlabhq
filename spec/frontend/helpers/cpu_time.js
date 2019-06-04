import subprocess from 'child_process';
import os from 'os';
import process from 'process';

const getSeconds = str => {
  const parts = str.trim().split(/[:.]/).map(val => Number(val)); // [minutes, seconds, hundredths]
  return parts[0] * 60 + parts[1] + parts[2] / 100;
};

/**
 * On *nix systems, tries to get the elapsed CPU time (user and kernelspace), in seconds, of the current process. This is achieved via the `ps` command. Some nice day in the future, this may be implemented using a C extension and the `clock` posix function.
 *
 * On Windows, and wherever the `ps` command fails, returns the current process uptime, in seconds.
 */
// eslint-disable-next-line import/prefer-default-export
export const cpuTime = () => {
  // Node doesn't have a facility for getting the CPU time of its own process, so we must get it
  // from the `ps` command. Sadly, Linux and BSD `ps` are different, so we must handle each case.
  // Windows is not implemented at the moment.
  const platform = os.platform();
  try {
    if (platform === 'win32') {
      // Let's not support windows now
      return { time: process.uptime(), cpu: false };
    }

    const out = subprocess.execSync(`ps -p ${process.pid} -o time=`, { encoding: 'utf-8' });
    return { time: getSeconds(out), cpu: true };
  } catch (e) {
    // ps command failed
    return { time: process.uptime(), cpu: false };
  }
};

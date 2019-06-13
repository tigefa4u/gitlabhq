import * as cu from '~/lib/utils/common_utils';

const CMD_ENTITY = '&#8984;';

let platform;
Object.defineProperty(navigator, 'platform', {
  configurable: true,
  get: () => platform,
  set: val => {
    platform = val;
  },
});

describe('common_utils', () => {
  describe('platform leader key helpers', () => {
    const CTRL_EVENT = { ctrlKey: true };
    const META_EVENT = { metaKey: true };
    const BOTH_EVENT = { ctrlKey: true, metaKey: true };

    it('should return "ctrl" if navigator.platform is unset', () => {
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "meta" on MacOS', () => {
      navigator.platform = 'MacIntel';
      expect(cu.getPlatformLeaderKey()).toBe('meta');
      expect(cu.getPlatformLeaderKeyHTML()).toBe(CMD_ENTITY);
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Linux', () => {
      navigator.platform = 'Linux is great';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Windows', () => {
      navigator.platform = 'Win32';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });
  });
});

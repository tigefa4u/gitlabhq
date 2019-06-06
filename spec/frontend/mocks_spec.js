import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';

describe('Jest mocks', () => {
  describe('mock', () => {
    it('~/lib/utils/axios_utils', () =>
      expect(axios.get('http://gitlab.com')).rejects.toThrow('Unexpected unmocked request'));

    it('jQuery.ajax()', () => {
      expect($.ajax).toThrow('Unexpected unmocked');
    });
  });

  it('survive jest.resetModules()', () => {
      jest.resetModules();
      // eslint-disable-next-line global-require
      const axios2 = require('~/lib/utils/axios_utils').default;
      expect(axios2).toBe(axios); // It's still the same mock!
      return expect(axios2.get('http://gitlab.com')).rejects.toThrow('Unexpected unmocked request');
  });

  it('can be unmocked and remocked', () => {
    jest.dontMock('~/lib/utils/axios_utils');
    jest.resetModules();
    // eslint-disable-next-line global-require
    const axios2 = require('~/lib/utils/axios_utils').default;
    expect(axios2).not.toBe(axios);
    expect(axios2.isMock).toBeUndefined();

    jest.doMock('~/lib/utils/axios_utils');
    jest.resetModules();
    // eslint-disable-next-line global-require
    const axios3 = require('~/lib/utils/axios_utils').default;
    expect(axios3).not.toBe(axios2);
    expect(axios3.isMock).toBe(true);
  });
});

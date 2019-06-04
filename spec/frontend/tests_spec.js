import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils');

describe('Jest tests', () => {
  describe('mock', () => {
    it('~/lib/utils/axios_utils', () =>
      expect(axios.get('http://gitlab.com')).rejects.toThrow('Unexpected unmocked request'));

    it('jQuery.ajax()', () => {
      expect($.ajax).toThrow('Unexpected unmocked');
    });
  });
});

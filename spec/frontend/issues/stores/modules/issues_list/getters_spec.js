import state from '~/issues/stores/modules/issues_list/state';
import { hasFilters } from '~/issues/stores/modules/issues_list/getters';

describe('Issue List Getters', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('hasFilters', () => {
    it('should return "true" if current filters match issues filtered search tokens', () => {
      mockedState.filters = '?state=opened&label_name[]=Doing';
      expect(hasFilters(mockedState)).toEqual(true);
    });

    it('should return "false" if current filters dont match issues filtered search tokens', () => {
      mockedState.filters = '?scope=all&utf8=✓&state=opened';
      expect(hasFilters(mockedState)).toEqual(false);
    });

    it('should return "false" if there are no filters', () => {
      mockedState.filters = '';
      expect(hasFilters(mockedState)).toEqual(false);
    });
  });
});

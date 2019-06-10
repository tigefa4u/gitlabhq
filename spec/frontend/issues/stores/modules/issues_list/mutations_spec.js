import state from '~/issues/stores/modules/issues_list/state';
import mutations from '~/issues/stores/modules/issues_list/mutations';
import * as types from '~/issues/stores/modules/issues_list/mutation_types';

describe('Issues List Mutataions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('SET_LOADING_STATE', () => {
    it('sets the current loading state', () => {
      mockedState.loading = false;
      mutations[types.SET_LOADING_STATE](mockedState, true);

      expect(mockedState.loading).toEqual(true);
    });
  });

  describe('SET_FILTERS', () => {
    it('sets the current filters', () => {
      const mokedFilter = '?hello=worls';
      mockedState.filters = 'none';
      mutations[types.SET_FILTERS](mockedState, mokedFilter);

      expect(mockedState.filters).toEqual(mokedFilter);
    });
  });

  describe('SET_BULK_UPDATE_STATE', () => {
    it('updates bulk update status', () => {
      mockedState.isBulkUpdating = false;
      mutations[types.SET_BULK_UPDATE_STATE](mockedState, true);

      expect(mockedState.isBulkUpdating).toEqual(true);
    });
  });

  describe('SET_TOTAL_ITEMS', () => {
    it('sets the count of issues for pagination', () => {
      mockedState.totalItems = 0;
      mutations[types.SET_TOTAL_ITEMS](mockedState, '10');

      expect(mockedState.totalItems).toEqual(10);
    });
  });

  describe('SET_CURRENT_PAGE', () => {
    it('sets the current page value', () => {
      mockedState.currentPage = 0;
      mutations[types.SET_CURRENT_PAGE](mockedState, '1');

      expect(mockedState.currentPage).toEqual(1);
    });
  });

  describe('SET_ISSUES_DATA', () => {
    it('sets the current page value', () => {
      mockedState.issues = null;
      mutations[types.SET_ISSUES_DATA](mockedState, []);

      expect(mockedState.issues).toEqual([]);
    });
  });
});

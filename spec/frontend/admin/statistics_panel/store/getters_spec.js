import createState from '~/admin/statistics_panel/store/state';
import * as getters from '~/admin/statistics_panel/store/getters';

describe('Admin statistics panel getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('getStatisticsData', () => {
    it('', () => {
      state.statistics = { forks: 10, issues: 20 };

      const statisticsLabels = {
        forks: 'Forks',
        issues: 'Issues',
      };

      const statisticsData = [
        { key: 'forks', label: 'Forks', value: 10 },
        { key: 'issues', label: 'Issues', value: 20 },
      ];

      expect(getters.getStatisticsData(state)(statisticsLabels)).toEqual(statisticsData);
    });
  });
});

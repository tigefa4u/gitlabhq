/**
 * Merges the statisticsLabels with the state's data
 * and returns an array of the following form:
 * [{ key: "forks", label: "Forks", value: 50 }]
 */
export const getStatisticsData = state => statisticsLabels =>
  state.statistics
    ? Object.keys(statisticsLabels).map(key => {
        const result = {
          key,
          label: statisticsLabels[key],
          value: state.statistics[key] ? state.statistics[key] : null,
        };
        return result;
      })
    : null;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

import statisticsLabels from '../constants';

export const visibleStatistics = state =>
  Object.keys(statisticsLabels).map(key => {
    const result = { key, label: statisticsLabels[key], value: state.statistics[key] };
    return result;
  });

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

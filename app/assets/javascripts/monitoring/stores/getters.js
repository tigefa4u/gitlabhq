export const getMetricsCount = state => {
  return state.groups.reduce((count, group) => count + group.metrics.length, 0);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

export default () => ({
  hasMetrics: false,
  showPanels: true,
  clustersPath: null,
  tagsPath: null,
  projectPath: null,
  currentEnvironmentName: null, // Finish props
  metricsEndpoint: null,
  environmentsEndpoint: null,
  deploymentsEndpoint: null,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  selectedTimeWindow: null,
  groups: [],// From the monitoring store
  deploymentData: [],
  environmentsData: [],
});

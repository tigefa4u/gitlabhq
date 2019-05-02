<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import _ from 'underscore';
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import '~/vue_shared/mixins/is_ee';
import Flash from '../../flash';
import MonitoringService from '../services/monitoring_service';
import MonitorAreaChart from './charts/area.vue';
import LineChart from './charts/line.vue';
import SingleStatChart from './charts/single_stat.vue';
import HeatmapChart from './charts/heatmap.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import MonitoringStore from '../stores/monitoring_store';
import { timeWindows } from '../constants';
import { getTimeDiff } from '../utils';

const sidebarAnimationDuration = 150;
let sidebarMutationObserver;

export default {
  components: {
    MonitorAreaChart,
    GraphGroup,
    EmptyState,
    Icon,
    GlDropdown,
    GlDropdownItem,
    LineChart,
    SingleStatChart,
    HeatmapChart,
  },

  props: {
    hasMetrics: {
      type: Boolean,
      required: false,
      default: true,
    },
    showPanels: {
      type: Boolean,
      required: false,
      default: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    settingsPath: {
      type: String,
      required: true,
    },
    clustersPath: {
      type: String,
      required: true,
    },
    tagsPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    metricsEndpoint: {
      type: String,
      required: true,
    },
    deploymentEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    emptyGettingStartedSvgPath: {
      type: String,
      required: true,
    },
    emptyLoadingSvgPath: {
      type: String,
      required: true,
    },
    emptyNoDataSvgPath: {
      type: String,
      required: true,
    },
    emptyUnableToConnectSvgPath: {
      type: String,
      required: true,
    },
    environmentsEndpoint: {
      type: String,
      required: true,
    },
    currentEnvironmentName: {
      type: String,
      required: true,
    },
    showTimeWindowDropdown: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['groups', 'emptyState', 'showEmptyState']),
  },
  data() {
    return {
      store: new MonitoringStore(),
      state: 'gettingStarted',
      elWidth: 0,
      selectedTimeWindow: '',
    };
  },
  created() {
    this.setMetricsEndpoint(this.metricsEndpoint);
    this.setDeploymentsEndpoint(this.deploymentEndpoint);
    this.setEnvironmentsEndpoint(this.environmentsEndpoint);

    // TODO: Move all of this to the monitoring vuex store/state
    this.service = new MonitoringService({
      metricsEndpoint: this.metricsEndpoint,
      deploymentEndpoint: this.deploymentEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
    });

    this.timeWindows = timeWindows;
    this.selectedTimeWindow = this.timeWindows.eightHours;
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  mounted() {
    this.servicePromises = [
      this.service
        .getDeploymentData()
        .then(data => this.store.storeDeploymentData(data))
        .catch(() => Flash(s__('Metrics|There was an error getting deployment information.'))),
    ];

    if (!this.hasMetrics) {
      // TODO: This should be coming from a mutation/computedGetter
      // this.state = 'gettingStarted';
    } else {
      if (this.environmentsEndpoint) {
        this.servicePromises.push(
          this.service
            .getEnvironmentsData()
            .then(data => this.store.storeEnvironmentsData(data))
            .catch(() =>
              Flash(s__('Metrics|There was an error getting environments information.')),
            ),
        );
      }
      // TODO: Use this instead of the monitoring_service methods
      this.fetchMetricsData(getTimeDiff(this.timeWindows.eightHours));
      // this.getGraphsData();
      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    }
  },
  methods: {
    ...mapActions([
      'fetchMetricsData',
      'setMetricsEndpoint',
      'setDeploymentsEndpoint',
      'setEnvironmentsEndpoint',
    ]),
    getGraphAlerts(queries) {
      if (!this.allAlerts) return {};
      const metricIdsForChart = queries.map(q => q.metricId);
      return _.pick(this.allAlerts, alert => metricIdsForChart.includes(alert.metricId));
    },
    getGraphAlertValues(queries) {
      return Object.values(this.getGraphAlerts(queries));
    },
    getGraphsData() {
      // this.state = 'loading';
      Promise.all(this.servicePromises)
        .then(() => {
          if (this.groups.length < 1) {
            this.state = 'noData';
            return;
          }

          // this.showEmptyState = false; TODO: Delete me
        })
        .catch(() => {
          // this.state = 'unableToConnect';
        });
    },
    getGraphsDataWithTime(timeFrame) {
      // this.state = 'loading';
      // this.showEmptyState = true; TODO: Delete me!
      this.service
        .getGraphsData(getTimeDiff(this.timeWindows[timeFrame]))
        .then(data => {
          this.store.storeMetrics(data);
          this.selectedTimeWindow = this.timeWindows[timeFrame];
        })
        .catch(() => {
          Flash(s__('Metrics|Not enough data to display'));
        })
        .finally(() => {
          // this.showEmptyState = false; TODO: Delete me!
        });
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
    activeTimeWindow(key) {
      return this.timeWindows[key] === this.selectedTimeWindow;
    },
  },
};
</script>

<template>
  <div v-if="!showEmptyState" class="prometheus-graphs prepend-top-default">
    <!-- <div
      v-if="environmentsEndpoint"
      class="dropdowns d-flex align-items-center justify-content-between"
    >
      <div class="d-flex align-items-center">
        <strong>{{ s__('Metrics|Environment') }}</strong>
        <gl-dropdown
          class="prepend-left-10 js-environments-dropdown"
          toggle-class="dropdown-menu-toggle"
          :text="currentEnvironmentName"
          :disabled="store.environmentsData.length === 0"
        >
          <gl-dropdown-item
            v-for="environment in store.environmentsData"
            :key="environment.id"
            :href="environment.metrics_path"
            :active="environment.name === currentEnvironmentName"
            active-class="is-active"
            >{{ environment.name }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
      <div v-if="showTimeWindowDropdown" class="d-flex align-items-center">
        <strong>{{ s__('Metrics|Show last') }}</strong>
        <gl-dropdown
          class="prepend-left-10 js-time-window-dropdown"
          toggle-class="dropdown-menu-toggle"
          :text="selectedTimeWindow"
        >
          <gl-dropdown-item
            v-for="(value, key) in timeWindows"
            :key="key"
            :active="activeTimeWindow(key)"
            @click="getGraphsDataWithTime(key)"
            >{{ value }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
    </div>
    -->
    <graph-group
      v-for="(groupData, index) in groups"
      :key="index"
      :name="groupData.group"
      :show-panels="showPanels"
    >
      <template v-for="(graphData, graphIndex) in groupData.metrics">
        <monitor-area-chart
          v-if="graphData.type === undefined || graphData.type === 'area'"
          :key="`area-${graphIndex}`"
          :graph-data="graphData"
          :deployment-data="store.deploymentData"
          :thresholds="getGraphAlertValues(graphData.queries)"
          :container-width="elWidth"
          group-id="monitor-area-chart"
        >
          <alert-widget
            v-if="isEE && prometheusAlertsAvailable && alertsEndpoint && graphData"
            :alerts-endpoint="alertsEndpoint"
            :relevant-queries="graphData.queries"
            :alerts-to-manage="getGraphAlerts(graphData.queries)"
            @setAlerts="setAlerts"
          />
        </monitor-area-chart>
        <single-stat-chart
          v-else-if="graphData.type === 'single_stat'"
          :key="`single-stat-${graphIndex}`"
          value="100"
          unit="ms"
          title="latency"
        />
        <line-chart
          v-else-if="graphData.type === 'line_chart'"
          :key="`line-${graphIndex}`"
          :graph-data="graphData"
          :container-width="elWidth"
        />
        <heatmap-chart
          v-else-if="graphData.type === 'heatmap_chart'"
          :key="`heatmap-${graphIndex}`"
          :graph-data="graphData"
        />
      </template>
    </graph-group>
  </div>
  <empty-state
    v-else
    :selected-state="emptyState"
    :documentation-path="documentationPath"
    :settings-path="settingsPath"
    :clusters-path="clustersPath"
    :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
    :empty-loading-svg-path="emptyLoadingSvgPath"
    :empty-no-data-svg-path="emptyNoDataSvgPath"
    :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
  />
</template>

<script>
import { mapActions, mapState } from 'vuex';
import GraphGroup from './graph_group.vue';
import MonitorAreaChart from './charts/area.vue';
import { timeWindowsKeyNames, timeWindows } from '../constants';
import { getTimeDiff } from '../utils';

const sidebarAnimationDuration = 150;
let sidebarMutationObserver;

// This component will only be injected when both the environment_metrics_use_prometheus_endpoint
// and environment_metrics_show_multiple_dashboards feature flags are enabled.
export default {
  components: {
    GraphGroup,
    MonitorAreaChart,
  },
  props: {
    link: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      params: {
        embedded: true,
        ...getTimeDiff(timeWindows[timeWindowsKeyNames.eightHours]),
      },
      elWidth: 0,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['groups', 'metricsWithData']),
    groupsWithData() {
      const groupsWithData = this.groups.filter(
        group => this.chartsWithData(group.metrics).length > 0,
      );
      return groupsWithData;
    },
  },
  mounted() {
    this.setDashboardEnabled(true);
    this.setShowErrorBanner(false);
    this.$nextTick(() => {
      // TODO: Move earlier in the lifecycle.
      this.setEndpoints({
        dashboardEndpoint: this.link,
      });
      // TODO: Cancel requests when navigating away from page / clicking edit.
      // TODO: Handle case where permissions isn't granted.
      // TODO: Handle case where project or dashboard doesn't exist.
      // TODO: Hide error when link is invalid.
      this.fetchMetricsData(this.params);
      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    });
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'fetchMetricsData',
      'setEndpoints',
      'setDashboardEnabled',
      'setShowErrorBanner',
    ]),
    chartsWithData(charts) {
      return charts.filter(chart =>
        chart.metrics.some(metric => this.metricsWithData.includes(metric.metric_id)),
      );
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
  },
};
</script>
<template>
  <div class="metrics-embed">
    <div v-for="(groupData, index) in groupsWithData" :key="index" class="row w-100 m-n2 pb-4">
      <monitor-area-chart
        v-for="(graphData, graphIndex) in chartsWithData(groupData.metrics)"
        :key="graphIndex"
        :graph-data="graphData"
        :container-width="elWidth"
        group-id="monitor-area-chart"
        :show-border="true"
      />
    </div>
  </div>
</template>

<script>
import { mapActions, mapState } from 'vuex';
import GraphGroup from './graph_group.vue';
import MonitorAreaChart from './charts/area.vue';
import { sidebarAnimationDuration, timeWindowsKeyNames, timeWindows } from '../constants';
import { getTimeDiff } from '../utils';

let sidebarMutationObserver;

export default {
  components: {
    GraphGroup,
    MonitorAreaChart,
  },
  props: {
    dashboardUrl: {
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
      return this.groups.filter(group => this.chartsWithData(group.metrics).length);
    },
  },
  mounted() {
    this.setInitialState();
    this.$nextTick(() => {
      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
      this.fetchMetricsData(this.params);
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
      'setFeatureFlags',
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
    setInitialState() {
      this.setFeatureFlags({
        prometheusEndpointEnabled: true,
      });
      this.setEndpoints({
        dashboardEndpoint: this.dashboardUrl,
      });
      this.setShowErrorBanner(false);
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
        :project-path="null"
        :show-border="true"
      />
    </div>
  </div>
</template>

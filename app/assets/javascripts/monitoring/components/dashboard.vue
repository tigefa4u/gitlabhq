<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import Flash from '../../flash';
import MonitoringService from '../services/monitoring_service';
import MonitorAreaChart from './charts/area.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import MonitoringStore from '../stores/monitoring_store';
import { timeWindows } from '../constants';

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
  },
  data() {
    return {
      store: new MonitoringStore(),
      state: 'gettingStarted',
      showEmptyState: true,
      elWidth: 0,
      selectedTimeWindow: '',
    };
  },
  created() {
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
    if (!this.hasMetrics) {
      this.state = 'gettingStarted';
    } else {
      this.getGraphsData();
      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    }
  },
  methods: {
    getGraphAlerts(graphId) {
      return this.alertData ? this.alertData[graphId] || {} : {};
    },
    getGraphsData() {
      this.state = 'loading';
      Promise.all([
        this.service.getGraphsData().then(data => this.store.storeMetrics(data)),
        this.service
          .getDeploymentData()
          .then(data => this.store.storeDeploymentData(data))
          .catch(() => Flash(s__('Metrics|There was an error getting deployment information.'))),
        this.service
          .getEnvironmentsData()
          .then(data => this.store.storeEnvironmentsData(data))
          .catch(() => Flash(s__('Metrics|There was an error getting environments information.'))),
      ])
        .then(() => {
          if (this.store.groups.length < 1) {
            this.state = 'noData';
            return;
          }

          this.showEmptyState = false;
        })
        .catch(() => {
          this.state = 'unableToConnect';
        });
    },
    getGraphsDataWithTime(timeFrame) {
      this.selectedTimeWindow = this.timeWindows[timeFrame];
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
    <div class="dropdowns d-flex align-items-center justify-content-between">
      <div class="d-flex align-items-center">
        <span class="font-weight-bold">{{ s__('Metrics|Environment') }}</span>
        <div class="dropdown prepend-left-10">
          <button class="dropdown-menu-toggle" data-toggle="dropdown" type="button">
            <span>{{ currentEnvironmentName }}</span>
            <icon name="chevron-down" />
          </button>
          <div
            v-if="store.environmentsData.length > 0"
            class="dropdown-menu dropdown-menu-selectable dropdown-menu-drop-up js-environments-dropdown"
          >
            <ul>
              <li v-for="environment in store.environmentsData" :key="environment.id">
                <a
                  :href="environment.metrics_path"
                  :class="{ 'is-active': environment.name == currentEnvironmentName }"
                  class="dropdown-item"
                  >{{ environment.name }}</a
                >
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div class="d-flex align-items-center">
        <span class="font-weight-bold">{{ s__('Metrics|Show Last') }}</span>
        <gl-dropdown
          id="time-window-dropdown"
          class="prepend-left-10"
          toggle-class="dropdown-menu-toggle"
          :text="selectedTimeWindow"
        >
          <gl-dropdown-item
            v-for="(value, key) in timeWindows"
            :key="key"
            :active="activeTimeWindow(key)"
            @click="getGraphsDataWithTime(key)"
            >{{ value }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
    </div>
    <graph-group
      v-for="(groupData, index) in store.groups"
      :key="index"
      :name="groupData.group"
      :show-panels="showPanels"
    >
      <monitor-area-chart
        v-for="(graphData, graphIndex) in groupData.metrics"
        :key="graphIndex"
        :graph-data="graphData"
        :deployment-data="store.deploymentData"
        :alert-data="getGraphAlerts(graphData.id)"
        :container-width="elWidth"
        group-id="monitor-area-chart"
      />
    </graph-group>
  </div>
  <empty-state
    v-else
    :selected-state="state"
    :documentation-path="documentationPath"
    :settings-path="settingsPath"
    :clusters-path="clustersPath"
    :empty-getting-started-svg-path="emptyGettingStartedSvgPath"
    :empty-loading-svg-path="emptyLoadingSvgPath"
    :empty-no-data-svg-path="emptyNoDataSvgPath"
    :empty-unable-to-connect-svg-path="emptyUnableToConnectSvgPath"
  />
</template>

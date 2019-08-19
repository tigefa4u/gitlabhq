<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import _ from 'underscore';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import { getParameterValues, mergeUrlParams } from '~/lib/utils/url_utility';
import invalidUrl from '~/lib/utils/invalid_url';
import PanelType from 'ee_else_ce/monitoring/components/panel_type.vue';
import MonitorTimeSeriesChart from './charts/time_series.vue';
import MonitorSingleStatChart from './charts/single_stat.vue';
import GraphGroup from './graph_group.vue';
import EmptyState from './empty_state.vue';
import { sidebarAnimationDuration, timeWindows } from '../constants';
import { getTimeDiff, getTimeWindow } from '../utils';

let sidebarMutationObserver;

export default {
  components: {
    MonitorTimeSeriesChart,
    MonitorSingleStatChart,
    PanelType,
    GraphGroup,
    EmptyState,
    Icon,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    externalDashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
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
    deploymentsEndpoint: {
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
    customMetricsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    customMetricsPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    validateQueryPath: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    dashboardEndpoint: {
      type: String,
      required: false,
      default: invalidUrl,
    },
    currentDashboard: {
      type: String,
      required: false,
      default: '',
    },
    smallEmptyState: {
      type: Boolean,
      required: false,
      default: false,
    },
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    prometheusAlertsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      state: 'gettingStarted',
      elWidth: 0,
      selectedTimeWindow: '',
      selectedTimeWindowKey: '',
      formIsValid: null,
      timeWindows: {},
    };
  },
  computed: {
    canAddMetrics() {
      return this.customMetricsAvailable && this.customMetricsPath.length;
    },
    ...mapState('monitoringDashboard', [
      'groups',
      'emptyState',
      'showEmptyState',
      'environments',
      'deploymentData',
      'metricsWithData',
      'useDashboardEndpoint',
      'allDashboards',
      'multipleDashboardsEnabled',
    ]),
    firstDashboard() {
      return this.allDashboards[0] || {};
    },
    selectedDashboardText() {
      return this.currentDashboard || this.firstDashboard.display_name;
    },
    addingMetricsAvailable() {
      return IS_EE && this.canAddMetrics && !this.showEmptyState;
    },
  },
  created() {
    this.setEndpoints({
      metricsEndpoint: this.metricsEndpoint,
      environmentsEndpoint: this.environmentsEndpoint,
      deploymentsEndpoint: this.deploymentsEndpoint,
      dashboardEndpoint: this.dashboardEndpoint,
      currentDashboard: this.currentDashboard,
      projectPath: this.projectPath,
    });
  },
  beforeDestroy() {
    if (sidebarMutationObserver) {
      sidebarMutationObserver.disconnect();
    }
  },
  mounted() {
    if (!this.hasMetrics) {
      this.setGettingStartedEmptyState();
    } else {
      const defaultRange = getTimeDiff();
      const start = getParameterValues('start')[0] || defaultRange.start;
      const end = getParameterValues('end')[0] || defaultRange.end;

      const range = {
        start,
        end,
      };

      this.timeWindows = timeWindows;
      this.selectedTimeWindowKey = getTimeWindow(range);
      this.selectedTimeWindow = this.timeWindows[this.selectedTimeWindowKey];

      this.fetchData(range);

      sidebarMutationObserver = new MutationObserver(this.onSidebarMutation);
      sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
        attributes: true,
        childList: false,
        subtree: false,
      });
    }
  },
  methods: {
    ...mapActions('monitoringDashboard', [
      'fetchData',
      'setGettingStartedEmptyState',
      'setEndpoints',
      'setDashboardEnabled',
    ]),
    chartsWithData(charts) {
      if (!this.useDashboardEndpoint) {
        return charts;
      }
      return charts.filter(chart =>
        chart.metrics.some(metric => this.metricsWithData.includes(metric.metric_id)),
      );
    },
    generateLink(group, title, yLabel) {
      const dashboard = this.currentDashboard || this.firstDashboard.path;
      const params = _.pick({ dashboard, group, title, y_label: yLabel }, value => value != null);
      return mergeUrlParams(params, window.location.href);
    },
    hideAddMetricModal() {
      this.$refs.addMetricModal.hide();
    },
    onSidebarMutation() {
      setTimeout(() => {
        this.elWidth = this.$el.clientWidth;
      }, sidebarAnimationDuration);
    },
    setFormValidity(isValid) {
      this.formIsValid = isValid;
    },
    submitCustomMetricsForm() {
      this.$refs.customMetricsForm.submit();
    },
    activeTimeWindow(key) {
      return this.timeWindows[key] === this.selectedTimeWindow;
    },
    setTimeWindowParameter(key) {
      const { start, end } = getTimeDiff(key);
      return `?start=${encodeURIComponent(start)}&end=${encodeURIComponent(end)}`;
    },
    groupHasData(group) {
      return this.chartsWithData(group.metrics).length > 0;
    },
  },
  addMetric: {
    title: s__('Metrics|Add metric'),
    modalId: 'add-metric',
  },
};
</script>

<template>
  <div class="prometheus-graphs">
    <div class="gl-p-3 pb-0 border-bottom bg-gray-light">
      <div class="row">
        <template v-if="environmentsEndpoint">
          <gl-form-group
            v-if="multipleDashboardsEnabled"
            :label="__('Dashboard')"
            label-size="sm"
            label-for="monitor-dashboards-dropdown"
            class="col-sm-12 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-dashboards-dropdown"
              class="mb-0 d-flex js-dashboards-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="selectedDashboardText"
            >
              <gl-dropdown-item
                v-for="dashboard in allDashboards"
                :key="dashboard.path"
                :active="dashboard.path === currentDashboard"
                active-class="is-active"
                :href="`?dashboard=${dashboard.path}`"
                >{{ dashboard.display_name || dashboard.path }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            :label="s__('Metrics|Environment')"
            label-size="sm"
            label-for="monitor-environments-dropdown"
            class="col-sm-6 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-environments-dropdown"
              class="mb-0 d-flex js-environments-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="currentEnvironmentName"
              :disabled="environments.length === 0"
            >
              <gl-dropdown-item
                v-for="environment in environments"
                :key="environment.id"
                :active="environment.name === currentEnvironmentName"
                active-class="is-active"
                :href="environment.metrics_path"
                >{{ environment.name }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>

          <gl-form-group
            v-if="!showEmptyState"
            :label="s__('Metrics|Show last')"
            label-size="sm"
            label-for="monitor-time-window-dropdown"
            class="col-sm-6 col-md-4 col-lg-2"
          >
            <gl-dropdown
              id="monitor-time-window-dropdown"
              class="mb-0 d-flex js-time-window-dropdown"
              toggle-class="dropdown-menu-toggle"
              :text="selectedTimeWindow"
            >
              <gl-dropdown-item
                v-for="(value, key) in timeWindows"
                :key="key"
                :active="activeTimeWindow(key)"
                :href="setTimeWindowParameter(key)"
                active-class="active"
                >{{ value }}</gl-dropdown-item
              >
            </gl-dropdown>
          </gl-form-group>
        </template>

        <gl-form-group
          v-if="addingMetricsAvailable || externalDashboardUrl.length"
          label-for="prometheus-graphs-dropdown-buttons"
          class="dropdown-buttons col-lg d-lg-flex align-items-end"
        >
          <div id="prometheus-graphs-dropdown-buttons">
            <gl-button
              v-if="addingMetricsAvailable"
              v-gl-modal="$options.addMetric.modalId"
              class="mr-2 mt-1 js-add-metric-button text-success border-success"
            >
              {{ $options.addMetric.title }}
            </gl-button>
            <gl-modal
              v-if="addingMetricsAvailable"
              ref="addMetricModal"
              :modal-id="$options.addMetric.modalId"
              :title="$options.addMetric.title"
            >
              <form ref="customMetricsForm" :action="customMetricsPath" method="post">
                <custom-metrics-form-fields
                  :validate-query-path="validateQueryPath"
                  form-operation="post"
                  @formValidation="setFormValidity"
                />
              </form>
              <div slot="modal-footer">
                <gl-button @click="hideAddMetricModal">{{ __('Cancel') }}</gl-button>
                <gl-button
                  :disabled="!formIsValid"
                  variant="success"
                  @click="submitCustomMetricsForm"
                >
                  {{ __('Save changes') }}
                </gl-button>
              </div>
            </gl-modal>

            <gl-button
              v-if="externalDashboardUrl.length"
              class="mt-1 js-external-dashboard-link"
              variant="primary"
              :href="externalDashboardUrl"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ __('View full dashboard') }}
              <icon name="external-link" />
            </gl-button>
          </div>
        </gl-form-group>
      </div>
    </div>

    <div v-if="!showEmptyState">
      <graph-group
        v-for="(groupData, index) in groups"
        :key="`${groupData.group}.${groupData.priority}`"
        :name="groupData.group"
        :show-panels="showPanels"
        :collapse-group="groupHasData(groupData)"
      >
        <panel-type
          v-for="(graphData, graphIndex) in groupData.metrics"
          :key="`panel-type-${graphIndex}`"
          :clipboard-text="generateLink(groupData.group, graphData.title, graphData.y_label)"
          :graph-data="graphData"
          :dashboard-width="elWidth"
          :index="`${index}-${graphIndex}`"
        />
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
      :compact="smallEmptyState"
    />
  </div>
</template>

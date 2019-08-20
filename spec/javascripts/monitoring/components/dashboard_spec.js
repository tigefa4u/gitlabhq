import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { timeWindows, timeWindowsKeyNames } from '~/monitoring/constants';
import * as types from '~/monitoring/stores/mutation_types';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import {
  metricsGroupsAPIResponse,
  mockedQueryResultPayload,
  mockApiEndpoint,
  environmentData,
  dashboardGitResponse,
} from '../mock_data';

const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  metricsEndpoint: mockApiEndpoint,
  deploymentsEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

export default propsData;

function setupComponentStore(component) {
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
    metricsGroupsAPIResponse,
  );
  component.$store.commit(
    `monitoringDashboard/${types.SET_QUERY_RESULT}`,
    mockedQueryResultPayload,
  );
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
    environmentData,
  );
}

describe('Dashboard', () => {
  let DashboardComponent;
  let mock;
  let store;
  let component;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    window.gon = {
      ...window.gon,
      ee: false,
    };

    store = createStore();
    mock = new MockAdapter(axios);
    DashboardComponent = Vue.extend(Dashboard);
  });

  afterEach(() => {
    if (component) {
      component.$destroy();
    }
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData },
        store,
      });
    });

    it('shows a getting started empty state when no metrics are present', () => {
      expect(component.$el.querySelector('.prometheus-graphs')).toBe(null);
      expect(component.emptyState).toEqual('gettingStarted');
    });

    it('shows the environment selector', () => {
      expect(component.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('no data found', () => {
    it('shows the environment selector dropdown', () => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, showEmptyState: true },
        store,
      });

      expect(component.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('requests information to the server', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    describe('when all the requests have been commited by the store', () => {
      beforeEach(() => {
        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: {
            ...propsData,
            hasMetrics: true,
          },
          store,
        });

        setupComponentStore(component);
      });

      it('renders the environments dropdown with a number of environments', done => {
        Vue.nextTick()
          .then(() => {
            const dropdownMenuEnvironments = component.$el.querySelectorAll(
              '.js-environments-dropdown .dropdown-item',
            );

            expect(component.environments.length).toEqual(environmentData.length);
            expect(dropdownMenuEnvironments.length).toEqual(component.environments.length);

            Array.from(dropdownMenuEnvironments).forEach((value, index) => {
              if (environmentData[index].metrics_path) {
                expect(value).toHaveAttr('href', environmentData[index].metrics_path);
              }
            });

            done();
          })
          .catch(done.fail);
      });

      it('renders the environments dropdown with a single active element', done => {
        Vue.nextTick()
          .then(() => {
            const dropdownItems = component.$el.querySelectorAll(
              '.js-environments-dropdown .dropdown-item.active',
            );

            expect(dropdownItems.length).toEqual(1);
            done();
          })
          .catch(done.fail);
      });

      it('hides the group panels when showPanels is false', done => {
        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: {
            ...propsData,
            hasMetrics: true,
            showPanels: false,
          },
          store,
        });

        setupComponentStore(component);

        Vue.nextTick()
          .then(() => {
            expect(component.showEmptyState).toEqual(false);
            expect(component.$el.querySelector('.prometheus-panel')).toEqual(null);
            expect(component.$el.querySelector('.prometheus-graph-group')).toBeTruthy();

            done();
          })
          .catch(done.fail);
      });

      it('shows a specific time window selected from the url params', done => {
        const start = 1564439536;
        const end = 1564441336;
        spyOnDependency(Dashboard, 'getTimeDiff').and.returnValue({
          start,
          end,
        });
        spyOnDependency(Dashboard, 'getParameterValues').and.callFake(param => {
          if (param === 'start') return [start];
          if (param === 'end') return [end];
          return [];
        });

        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: { ...propsData, hasMetrics: true },
          store,
        });

        setupComponentStore(component);

        Vue.nextTick(() => {
          const selectedTimeWindow = component.$el.querySelector(
            '.js-time-window-dropdown .active',
          );

          expect(selectedTimeWindow.textContent.trim()).toEqual('30 minutes');
          done();
        });
      });

      it('renders the time window dropdown with a set of options', done => {
        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: {
            ...propsData,
            hasMetrics: true,
          },
          store,
        });

        setupComponentStore(component);

        const numberOfTimeWindows = Object.keys(timeWindows).length;

        Vue.nextTick(() => {
          const timeWindowDropdown = component.$el.querySelector('.js-time-window-dropdown');
          const timeWindowDropdownEls = component.$el.querySelectorAll(
            '.js-time-window-dropdown .dropdown-item',
          );

          expect(timeWindowDropdown).not.toBeNull();
          expect(timeWindowDropdownEls.length).toEqual(numberOfTimeWindows);

          done();
        });
      });
    });

    it('hides the environments dropdown list when there is no environments', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
        },
        store,
      });

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        metricsGroupsAPIResponse,
      );
      component.$store.commit(
        `monitoringDashboard/${types.SET_QUERY_RESULT}`,
        mockedQueryResultPayload,
      );

      Vue.nextTick()
        .then(() => {
          const dropdownMenuEnvironments = component.$el.querySelectorAll(
            '.js-environments-dropdown .dropdown-item',
          );

          expect(dropdownMenuEnvironments.length).toEqual(0);
          done();
        })
        .catch(done.fail);
    });

    it('hides the environments dropdown', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          environmentsEndpoint: '',
        },
        store,
      });

      Vue.nextTick(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll('.environments');

        expect(dropdownIsActiveElement.length).toEqual(0);
        done();
      });
    });

    it('fetches the metrics data with proper time window', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      spyOn(component.$store, 'dispatch').and.stub();
      const getTimeDiffSpy = spyOnDependency(Dashboard, 'getTimeDiff').and.callThrough();

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      component.$mount();

      Vue.nextTick()
        .then(() => {
          expect(component.$store.dispatch).toHaveBeenCalled();
          expect(getTimeDiffSpy).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('defaults to the eight hours time window for non valid url parameters', done => {
      spyOnDependency(Dashboard, 'getParameterValues').and.returnValue([
        '<script>alert("XSS")</script>',
      ]);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      Vue.nextTick(() => {
        expect(component.selectedTimeWindowKey).toEqual(timeWindowsKeyNames.eightHours);

        done();
      });
    });
  });

  describe('link to chart', () => {
    let wrapper;
    const currentDashboard = 'TEST_DASHBOARD';

    beforeEach(done => {
      wrapper = shallowMount(DashboardComponent, {
        sync: false,
        attachToDocument: true,
        propsData: { ...propsData, hasMetrics: true, currentDashboard },
        store,
      });

      setTimeout(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('generates a link to a chart', () => {
      const generatedLink = wrapper.vm.generateLink('kubernetes', 'core usage', '%');

      expect(generatedLink).toContain(`dashboard=${currentDashboard}`);
      expect(generatedLink).toContain(`group=`);
      expect(generatedLink).toContain(`title=`);
      expect(generatedLink).toContain(`y_label=`);
    });
  });

  describe('when the window resizes', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    it('sets elWidth to page width when the sidebar is resized', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      expect(component.elWidth).toEqual(0);

      const pageLayoutEl = document.querySelector('.layout-page');
      pageLayoutEl.classList.add('page-with-icon-sidebar');

      Vue.nextTick()
        .then(() => {
          jasmine.clock().tick(1000);
          return Vue.nextTick();
        })
        .then(() => {
          expect(component.elWidth).toEqual(pageLayoutEl.clientWidth);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('external dashboard link', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
          externalDashboardUrl: '/mockUrl',
        },
        store,
      });
    });

    it('shows the link', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-external-dashboard-link').innerText).toContain(
          'View full dashboard',
        );
        done();
      });
    });
  });

  describe('Dashboard dropdown', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      component.$store.dispatch('monitoringDashboard/setFeatureFlags', {
        prometheusEndpoint: false,
        multipleDashboardsEnabled: true,
      });

      component.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );
    });

    it('shows the dashboard dropdown', done => {
      setTimeout(() => {
        const dashboardDropdown = component.$el.querySelector('.js-dashboards-dropdown');

        expect(dashboardDropdown).not.toEqual(null);
        done();
      });
    });
  });
});

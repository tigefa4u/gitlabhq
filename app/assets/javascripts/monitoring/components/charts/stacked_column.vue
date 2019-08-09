<script>
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight } from '../../constants';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlStackedColumnChart,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, false),
    },
    containerWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      width: 0,
      height: chartHeight,
      svgs: {},
    };
  },
  computed: {
    chartData() {
      // TODO: Process this data from the graphData prop
      return [
        [58, 49, 38, 23, 27, 68, 38, 35, 7, 64, 65, 31],
        [8, 6, 34, 19, 9, 7, 17, 25, 14, 7, 10, 32],
        [67, 60, 66, 32, 61, 54, 13, 50, 16, 11, 47, 28],
        [8, 9, 5, 40, 13, 19, 58, 21, 47, 59, 23, 46],
      ];
    },
    xAxisTitle() {
      return this.graphData.queries[0].result[0].x_label !== undefined
        ? this.graphData.queries[0].result[0].x_label
        : '';
    },
    yAxisTitle() {
      return this.graphData.queries[0].result[0].y_label !== undefined
        ? this.graphData.queries[0].result[0].y_label
        : '';
    },
    xAxisType() {
      return this.graphData.x_type !== undefined ? this.graphData.x_type : 'category';
    },
    groupBy() {
      // TODO: Process this data from the graphData prop
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    },
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    chartOptions() {
      return {
        dataZoom: this.dataZoomConfig,
      };
    },
    seriesNames() {
      // TODO: Process this data from the graphData prop
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return ['Fun 1', 'Fun 2', 'Fun 3', 'Fun 4'];
    },
  },
  created() {
    this.setSvg('scroll-handle');
  },
  methods: {
    setSvg(name) {
      getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
  },
};
</script>
<template>
  <div class="prometheus-graph col-12 col-lg-6">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div ref="graphWidgets" class="prometheus-graph-widgets"><slot></slot></div>
    </div>
    <gl-stacked-column-chart
      ref="stackedColumnChart"
      v-bind="$attrs"
      :data="chartData"
      :option="chartOptions"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      :x-axis-type="xAxisType"
      :group-by="groupBy"
      :width="width"
      :height="height"
      :series-names="seriesNames"
    />
  </div>
</template>

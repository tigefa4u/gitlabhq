<script>
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import dateformat from 'dateformat';
import { debounceByAnimationFrame } from '~/lib/utils/common_utils';
import { chartHeight } from '../../constants';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlHeatmap,
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
      debouncedResize: {},
      height: chartHeight,
      width: 0,
    };
  },
  computed: {
    chartData() {
      const [queries] = this.graphData.queries;
      const yDim = queries.result[0].values.length;
      const data = [];
      for (let j = 0; j < yDim; j += 1) {
        for (let i = 0; i < queries.result.length; i += 1) {
          const value = queries.result[i].values[j];

          data.push([i, j, value[1]]);
        }
      }

      return data;
    },
    xAxisName() {
      const xLabel = this.graphData.x_label;

      return xLabel != null ? xLabel : '';
    },
    yAxisName() {
      const yLabel = this.graphData.y_label;

      return yLabel != null ? yLabel : '';
    },
    xAxisLabels() {
      const [queries] = this.graphData.queries;
      const axisLabels = queries.result.reduce((acc, res) => {
        const [keyMetric] = Object.keys(res.metric);
        const keyValue = res.metric[keyMetric];

        return acc.concat(keyValue);
      }, []);

      return axisLabels;
    },
    yAxisLabels() {
      const [queries] = this.graphData.queries;
      const axisLabels = queries.result[0].values.reduce((acc, val) => {
        const [yLabel] = val;
        const convertedDate = new Date(yLabel);

        return acc.concat(dateformat(convertedDate, 'HH:MM:ss'));
      }, []);

      return axisLabels;
    },
  },
  watch: {
    containerWidth: 'onResize',
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.debouncedResize);
  },
  created() {
    this.debouncedResize = debounceByAnimationFrame(this.onResize);
    window.addEventListener('resize', this.debouncedResize);
  },
  methods: {
    onResize() {
      if (!this.$refs.heatmap) return;
      const { width } = this.$refs.heatmap.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>
<template>
  <div class="prometheus-graph col-12 col-lg-6">
    <div class="prometheus-graph-header">
      <h5 class="prometheus-graph-title js-graph-title">{{ graphData.title }}</h5>
    </div>
    <gl-heatmap
      ref="heatmapChart"
      v-bind="$attrs"
      :data-series="chartData"
      :x-axis-name="xAxisName"
      :y-axis-name="yAxisName"
      :x-axis-labels="xAxisLabels"
      :y-axis-labels="yAxisLabels"
      :height="height"
      :width="width"
    />
  </div>
</template>

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';
import { use } from 'echarts/core';
import { CanvasRenderer } from 'echarts/renderers';
import { PieChart, BarChart } from 'echarts/charts';

import VChart from 'vue-echarts';
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  DatasetComponent
} from 'echarts/components';

use([
  CanvasRenderer,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  BarChart,
  GridComponent,
  DatasetComponent
]);


const app = createApp({
  data() {
    return {
      pieOptions: {
        tooltip: {
          trigger: 'item',
          formatter: '{d}%',
        },
        series: [
          {
            name: 'Traffic Sources',
            type: 'pie',
            color: [
              '#6F2DC1',
              '#E9A845',
              '#5EC66F',
              '#3B99FD',
              '#BCC3CF',
            ],
            label: {
              show: false,
              position: 'center'
            },
            labelLine: {
              show: false
            },
            radius: ['40%', '70%'],
            itemStyle: {
              borderRadius: 10,
              borderColor: '#fff',
              borderWidth: 2
            },
            data: [
              { value: 4, name: 'Done' },
              { value: 3, name: 'In review' },
              { value: 5, name: 'Completed' },
              { value: 5, name: 'In progress' },
              { value: 1, name: 'Not started' },
            ],
          },
        ],
      },
      barOptions: {
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            type: 'shadow'
          }
        },
        xAxis: [
          {
            type: 'category',
            axisLabel: {
              hideOverlap: false,
              interval: 0,
              overflow: 'truncate',
              width: 80,
            },
            data: ['Bor K', 'Huan Pernados Dias Muran', 'Alex Smith', 'Pablito con Huan', 'Donnie Brasko', 'Pablo K', 'Ava White']
          }
        ],
        yAxis: [
          {
            type: 'value'
          }
        ],
        series: [
          {
            name: 'Not started',
            type: 'bar',
            stack: 'status',
            barWidth: '20',
            color: '#BCC3CF',

            emphasis: {
              focus: 'series'
            },
            data: [2, 4, 6, 4, 3, 1, 2]
          },
          {
            name: 'In progress',
            type: 'bar',
            color: '#3B99FD',
            stack: 'status',
            emphasis: {
              focus: 'series'
            },
            data: [10, 12, 21, 4, 2, 3, 4]
          },
          {
            name: 'Completed',
            type: 'bar',
            color: '#5EC66F',
            stack: 'status',
            emphasis: {
              focus: 'series'
            },
            data: [0, 3, 1, 2, 2, 3, 1]
          },
          {
            name: 'In review',
            type: 'bar',
            color: '#E9A845',
            stack: 'status',
            data: [2, 4, 3, 4, 5, 1, 2],
            emphasis: {
              focus: 'series'
            },
          },
          {
            name: 'Done',
            type: 'bar',
            color: '#6F2DC1',
            stack: 'status',
            emphasis: {
              focus: 'series'
            },
            data: [7, 5, 3, 6, 7, 8, 4]
          }
        ]
      }
    };
  },
});
app.component('VChart', VChart);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#charts');

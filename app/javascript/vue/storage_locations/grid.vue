<template>
  <div class="grid grid-cols-[1.5rem_auto] grid-rows-[1.5rem_auto] overflow-hidden">
    <div class="z-10 bg-sn-super-light-grey"></div>
    <div ref="columnsContainer" class="overflow-x-hidden overflow-y-scroll">
      <div :style="{'width': `${columnsList.length * 54}px`}">
        <div v-for="column in columnsList" :key="column" class="uppercase float-left flex items-center justify-center w-[54px] ">
          <span>{{ column }}</span>
        </div>
      </div>
    </div>
    <div ref="rowContainer" class="overflow-y-hidden overflow-x-scroll max-h-[70vh]">
      <div v-for="row in rowsList" :key="row" class="uppercase flex items-center justify-center h-[54px]">
        <span>{{ row }}</span>
      </div>
    </div>
    <div ref="cellsContainer" class="overflow-scroll max-h-[70vh]">
      <div class="grid" :style="{
        'grid-template-columns': `repeat(${columnsList.length}, 1fr)`,
        'width': `${columnsList.length * 54}px`
      }">
        <div v-for="cell in cellsList" :key="cell.row + cell.column" class="cell">
          <div class="w-[54px] h-[54px] uppercase items-center flex justify-center p-1
                      border border-solid !border-transparent !border-b-sn-grey !border-r-sn-grey"
              :class="{ '!border-t-sn-grey': cell.row === 0, '!border-l-sn-grey': cell.column === 0 }"
          >
            <div
              class="h-full w-full rounded-full items-center flex justify-center"
              @click="assignRow(cell.row, cell.column)"
              :class="{
                'bg-sn-background-green': cellIsOccupied(cell.row, cell.column),
                'bg-white cursor-pointer': !cellIsOccupied(cell.row, cell.column)
              }"
            >
              {{ rowsList[cell.row] }}{{ columnsList[cell.column] }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StorageLocationsGrid',
  props: {
    gridSize: {
      type: Array,
      required: true
    },
    assignedItems: {
      type: Array,
      default: () => []
    }
  },
  mounted() {
    this.$refs.cellsContainer.addEventListener('scroll', this.handleScroll);
    window.addEventListener('resize', this.handleScroll);
  },
  beforeUnmount() {
    this.$refs.cellsContainer.removeEventListener('scroll', this.handleScroll);
    window.removeEventListener('resize', this.handleScroll);
  },
  computed: {
    columnsList() {
      return Array.from({ length: this.gridSize[1] }, (v, i) => i + 1);
    },
    rowsList() {
      return Array.from({ length: this.gridSize[0] }, (v, i) => String.fromCharCode(97 + i));
    },
    cellsList() {
      const cells = [];
      for (let i = 0; i < this.gridSize[0]; i++) {
        for (let j = 0; j < this.gridSize[1]; j++) {
          cells.push({ row: i, column: j });
        }
      }
      return cells;
    }
  },
  methods: {
    cellIsOccupied(row, column) {
      return this.assignedItems.some((item) => item.position[0] === row + 1 && item.position[1] === column + 1);
    },
    assignRow(row, column) {
      if (this.cellIsOccupied(row, column)) {
        return;
      }
      this.$emit('assign', [row + 1, column + 1]);
    },
    handleScroll() {
      this.$refs.columnsContainer.scrollLeft = this.$refs.cellsContainer.scrollLeft;
      this.$refs.rowContainer.scrollTop = this.$refs.cellsContainer.scrollTop;

      if (this.$refs.rowContainer.scrollTop > 0) {
        this.$refs.columnsContainer.style.boxShadow = '0px 0px 20px 0px rgba(16, 24, 40, 0.20)';
      } else {
        this.$refs.columnsContainer.style.boxShadow = 'none';
      }

      if (this.$refs.columnsContainer.scrollLeft > 0) {
        this.$refs.rowContainer.style.boxShadow = '0px 0px 20px 0px rgba(16, 24, 40, 0.20)';
      } else {
        this.$refs.rowContainer.style.boxShadow = 'none';
      }
    }
  }
};
</script>

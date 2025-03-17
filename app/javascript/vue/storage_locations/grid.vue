<template>
  <div class="grid grid-cols-[1.5rem_auto] grid-rows-[1.5rem_auto] overflow-hidden">
    <div class="z-10 bg-sn-super-light-grey"></div>
    <div ref="columnsContainer" class="overflow-x-hidden">
      <div :style="{'width': `${columnsList.length * 54}px`}">
        <div v-for="column in columnsList" :key="column" @click="selectColumn(column)" class=" cursor-pointer uppercase float-left flex items-center justify-center w-[54px] ">
          <span>{{ column }}</span>
        </div>
      </div>
    </div>
    <div ref="rowContainer" class="overflow-y-hidden max-h-[70vh]">
      <div v-for="row in rowsList" :key="row" @click="selectRow(row)" class="cursor-pointer uppercase flex items-center justify-center h-[54px]">
        <span>{{ row }}</span>
      </div>
    </div>
    <div ref="cellsContainer" class="overflow-hidden max-h-[70vh] relative">
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
              class="h-full w-full rounded-full items-center flex justify-center cursor-pointer"
              @click="selectPosition(cell)"
              :class="{
                'bg-sn-background-green': cellIsOccupied(cell),
                'bg-sn-grey-100': cellIsHidden(cell),
                'bg-white': cellIsAvailable(cell),
                'bg-white border-sn-science-blue border-solid border-[1px]': cellIsSelected(cell),
              }"
            >
              <template v-if="cellIsHidden(cell)">
                <i class="sn-icon sn-icon-locked-task"></i>
              </template>
              <template v-else>
                {{ rowsList[cell.row] }}{{ columnsList[cell.column] }}
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global PerfectScrollbar */
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
    },
    selectedItems: {
      type: Array,
      default: () => []
    },
    selectedEmptyCells: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      scrollBar: null
    };
  },
  mounted() {
    this.$refs.cellsContainer.addEventListener('scroll', this.handleScroll);
    window.addEventListener('resize', this.handleScroll);
    this.scrollBar = new PerfectScrollbar(this.$refs.cellsContainer, { wheelSpeed: 0.5, minScrollbarLength: 20 });
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
    cellObject(cell) {
      return this.assignedItems.find((item) => item.position[0] === cell.row + 1 && item.position[1] === cell.column + 1);
    },
    cellIsOccupied(cell) {
      return this.cellObject(cell) && !this.cellObject(cell)?.hidden;
    },
    cellIsHidden(cell) {
      return this.cellObject(cell)?.hidden;
    },
    cellIsSelected(cell) {
      return this.selectedItems.some((item) => item.position[0] === cell.row + 1 && item.position[1] === cell.column + 1)
        || this.selectedEmptyCells.some((selectedCell) => selectedCell.row === cell.row && selectedCell.column === cell.column);
    },
    cellIsAvailable(cell) {
      return !this.cellIsOccupied(cell) && !this.cellIsHidden(cell);
    },
    selectPosition(cell) {
      if (this.cellIsOccupied(cell) || this.cellIsHidden(cell)) {
        this.$emit('select', this.cellObject(cell));
        return;
      }

      this.$emit('selectEmptyCell', cell);
    },
    selectRow(row) {
      let selected = 0;
      this.columnsList.forEach((column) => {
        const cell = { row: this.rowsList.indexOf(row), column: column - 1 };
        if (!this.cellIsSelected(cell) && !this.cellIsOccupied(cell) && !this.cellIsHidden(cell)) {
          this.$emit('selectEmptyCell', cell);
          selected += 1;
        }
      });
      if (selected === 0) {
        this.$emit('unselectRow', row);
      }
    },
    selectColumn(column) {
      let selected = 0;
      this.rowsList.forEach((row) => {
        const cell = { row: this.rowsList.indexOf(row), column: column - 1 };
        if (!this.cellIsSelected(cell) && !this.cellIsOccupied(cell) && !this.cellIsHidden(cell)) {
          this.$emit('selectEmptyCell', cell);
          selected += 1;
        }
      });
      if (selected === 0) {
        this.$emit('unselectColumn', column);
      }
    },
    handleScroll() {
      this.$refs.columnsContainer.scrollLeft = this.$refs.cellsContainer.scrollLeft;
      this.$refs.rowContainer.scrollTop = this.$refs.cellsContainer.scrollTop;

      if (this.$refs.cellsContainer.scrollLeft > this.$refs.columnsContainer.scrollLeft) {
        this.$refs.cellsContainer.scrollLeft = this.$refs.columnsContainer.scrollLeft;
      }

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

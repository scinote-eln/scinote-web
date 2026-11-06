export const TABLE_STATE_PERMISSIONS = [
  'columnsVisibility',
  'columnsOrder',
  'columnsWidth',
  'columnsPinning',
  'order',
  'perPage'
];

export const FULL_TABLE_STATE_PERMISSIONS = Object.freeze(
  Object.fromEntries(TABLE_STATE_PERMISSIONS.map((permission) => [permission, true]))
);

// ag-grid column state keys controlled by each permission
const COLUMN_STATE_KEYS = {
  columnsVisibility: ['hide'],
  columnsWidth: ['width', 'flex'],
  columnsPinning: ['pinned'],
  order: ['sort', 'sortIndex']
};

const GUARDED_COLUMN_KEYS = Object.values(COLUMN_STATE_KEYS).flat();

export const BASE_TABLE_STATE = {
  columnsState: null,
  order: null,
  perPage: 20
};

export function canOverride(permissions, attribute) {
  return !permissions || permissions[attribute] !== false;
}

function pick(object, keys) {
  return keys.reduce((result, key) => {
    if (object && Object.prototype.hasOwnProperty.call(object, key)) {
      result[key] = object[key];
    }
    return result;
  }, {});
}

function omit(object, keys) {
  return Object.keys(object || {}).reduce((result, key) => {
    if (!keys.includes(key)) result[key] = object[key];
    return result;
  }, {});
}

function mergeColumnsState(defaultColumns, userColumns, permissions) {
  if (!defaultColumns && !userColumns) return null;

  const defaultById = new Map((defaultColumns || []).map((col) => [col.colId, col]));
  const userById = new Map((userColumns || []).map((col) => [col.colId, col]));

  let orderSource;
  if (canOverride(permissions, 'columnsOrder') && userColumns) {
    orderSource = userColumns;
  } else {
    orderSource = defaultColumns || userColumns;
  }

  const colIds = orderSource.map((col) => col.colId);
  [...defaultById.keys(), ...userById.keys()].forEach((colId) => {
    if (!colIds.includes(colId)) colIds.push(colId);
  });

  return colIds.map((colId) => {
    const defaultCol = defaultById.get(colId) || {};
    const userCol = userById.get(colId);
    const column = { ...defaultCol, colId };

    if (!userCol) return column;

    Object.assign(column, omit(userCol, GUARDED_COLUMN_KEYS));

    Object.entries(COLUMN_STATE_KEYS).forEach(([permission, keys]) => {
      if (canOverride(permissions, permission)) {
        Object.assign(column, pick(userCol, keys));
      }
    });

    return column;
  });
}

export function buildTableState(defaultState, userState, permissions) {
  const base = { ...BASE_TABLE_STATE, ...(defaultState || {}) };
  const user = userState || {};

  const resolve = (attribute) => {
    const userHasValue = user[attribute] !== undefined && user[attribute] !== null;
    return canOverride(permissions, attribute) && userHasValue ? user[attribute] : base[attribute];
  };

  const userHasOrder = Object.prototype.hasOwnProperty.call(user, 'order');

  return {
    columnsState: mergeColumnsState(base.columnsState, user.columnsState, permissions),
    order: canOverride(permissions, 'order') && userHasOrder ? user.order : base.order,
    perPage: resolve('perPage')
  };
}

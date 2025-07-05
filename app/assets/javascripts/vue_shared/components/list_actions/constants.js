import { __ } from '~/locale';

export const ACTION_EDIT = 'edit';
export const ACTION_LEAVE = 'leave';
export const ACTION_RESTORE = 'restore';
export const ACTION_DELETE = 'delete';

export const BASE_ACTIONS = {
  [ACTION_EDIT]: {
    text: __('Edit'),
    order: 1,
  },
  [ACTION_RESTORE]: {
    text: __('Restore'),
    order: 2,
  },
  [ACTION_LEAVE]: {
    text: __('Leave group'),
    variant: 'danger',
    order: 3,
  },
  [ACTION_DELETE]: {
    text: __('Delete'),
    variant: 'danger',
    order: 4,
  },
};

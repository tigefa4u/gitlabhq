// eslint-disable-next-line import/prefer-default-export
export const setWindowLocation = value => {
  Object.defineProperty(window, 'location', {
    writable: true,
    value,
  });
};

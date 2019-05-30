/**
@module
This method provides convenience functions to help migrating from Karma/Jasmine
to Jest.
 */

export function createSpyObj(baseName, methods) {
  return methods.reduce(
    (obj, method) => Object.assign(obj, { [method]: jest.fn().mockName(`${baseName}#${method}`) }),
    {},
  );
}

export default {
  createSpyObj,
};

import { createAsyncAction } from '~/lib/utils/vuex/async_action';

describe('createAsyncAction', () => {
  let asyncRequest;
  let options;

  beforeEach(() => {
    asyncRequest = jest.fn();
    options = {
      asyncRequest,
      requestMutation: 'dummy requestMutation',
      receiveMutation: 'dummy receiveMutation',
      receiveErrorMutation: 'dummy receiveErrorMutation',
    };
  });

  it.each`
    mutation
    ${'requestMutation'}
    ${'receiveMutation'}
    ${'receiveErrorMutation'}
  `('throws an error if $mutation parameter is missing', ({ mutation }) => {
    asyncRequest.mockImplementation(() => new Promise());
    options[mutation] = null;

    expect(() => createAsyncAction(options)).toThrow();
  });

  describe('returned action', () => {
    let commit;
    let dummyPayload;

    const callAction = () => {
      const action = createAsyncAction(options);
      return action({ commit }, dummyPayload);
    };

    beforeEach(() => {
      commit = jest.fn();
    });

    it('throws an error if asyncRequest parameter is missing', () => {
      options.asyncRequest = null;

      expect(callAction).toThrow();
    });

    it('throws an error if asyncRequest parameter does not return a Promise', () => {
      asyncRequest.mockImplementation(() => 'something');

      expect(callAction).toThrow();
    });

    describe('without payload', () => {
      beforeEach(() => {
        dummyPayload = null;
      });

      it('commits requestMutation before calling asyncRequest', () => {
        expect.assertions(3);
        asyncRequest.mockImplementation((...args) => {
          expect(args).toEqual([{ commit }]);
          expect(commit).toHaveBeenCalledTimes(1);
          expect(commit).toHaveBeenCalledWith(options.requestMutation);
          return Promise.resolve();
        });

        return callAction();
      });

      it('commits requestMutation and receiveMutation for resolved Promise', () => {
        const dummyValue = 'Schlump';
        asyncRequest.mockResolvedValue(dummyValue);

        expect.assertions(4);
        return callAction().then(value => {
          expect(value).toBe(dummyValue);
          expect(commit).toHaveBeenCalledTimes(2);
          expect(commit).toHaveBeenCalledWith(options.requestMutation);
          expect(commit).toHaveBeenCalledWith(options.receiveMutation, { result: dummyValue });
        });
      });

      it('commits requestMutation and receiveErrorMutation for rejected Promise', () => {
        const dummyError = new Error('oh no :-(');
        asyncRequest.mockRejectedValue(dummyError);

        expect.assertions(4);
        return callAction().catch(error => {
          expect(error).toBe(dummyError);
          expect(commit).toHaveBeenCalledTimes(2);
          expect(commit).toHaveBeenCalledWith(options.requestMutation);
          expect(commit).toHaveBeenCalledWith(options.receiveErrorMutation, { error: dummyError });
        });
      });
    });

    describe('with payload', () => {
      beforeEach(() => {
        dummyPayload = '12$';
      });

      it('commits requestMutation before calling asyncRequest', () => {
        expect.assertions(3);
        asyncRequest.mockImplementation((...args) => {
          expect(args).toEqual([{ commit }, dummyPayload]);
          expect(commit).toHaveBeenCalledTimes(1);
          expect(commit).toHaveBeenCalledWith(options.requestMutation, { payload: dummyPayload });
          return Promise.resolve();
        });

        return callAction();
      });

      it('commits requestMutation and receiveMutation for resolved Promise', () => {
        const dummyValue = 'Blankenese';
        asyncRequest.mockResolvedValue(dummyValue);

        expect.assertions(4);
        return callAction().then(value => {
          expect(value).toBe(dummyValue);
          expect(commit).toHaveBeenCalledTimes(2);
          expect(commit).toHaveBeenCalledWith(options.requestMutation, { payload: dummyPayload });
          expect(commit).toHaveBeenCalledWith(options.receiveMutation, {
            payload: dummyPayload,
            result: dummyValue,
          });
        });
      });

      it('commits requestMutation and receiveErrorMutation for rejected Promise', () => {
        const dummyError = new Error('Bro Ken 8-(');
        asyncRequest.mockRejectedValue(dummyError);

        expect.assertions(4);
        return callAction().catch(error => {
          expect(error).toBe(dummyError);
          expect(commit).toHaveBeenCalledTimes(2);
          expect(commit).toHaveBeenCalledWith(options.requestMutation, { payload: dummyPayload });
          expect(commit).toHaveBeenCalledWith(options.receiveErrorMutation, {
            payload: dummyPayload,
            error: dummyError,
          });
        });
      });
    });
  });
});

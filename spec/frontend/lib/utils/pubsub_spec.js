import { publish, subscribe } from '~/lib/utils/pubsub';

describe('Pub/sub messaging', () => {
  it('sends and receives messages asynchronously', done => {
    const receiver1 = jest.fn();
    const receiver2 = jest.fn();
    const receiver3 = jest.fn();
    subscribe('namespace:topic', receiver1);
    subscribe('namespace:topic', receiver2);
    subscribe('namespace:topic2', receiver3);

    publish('shoudnotreceive', 'shouldnotreceive');
    publish('namespace:topic', 1);
    publish('namespace:topic', 2);
    publish('namespace:topic2', 3);

    // Receivers should not be called synchronously
    expect(receiver1).not.toHaveBeenCalled();
    expect(receiver2).not.toHaveBeenCalled();
    expect(receiver3).not.toHaveBeenCalled();

    setImmediate(() => {
      expect(receiver1.mock.calls).toEqual([[1], [2]]);
      expect(receiver2.mock.calls).toEqual([[1], [2]]);
      expect(receiver3.mock.calls).toEqual([[3]]);
      done();
    });
  });

  it('allows clients to unsubscribe', done => {
    const receiver = jest.fn();
    const unsubscribe = subscribe('topic', receiver);
    publish('topic', 1);
    unsubscribe();
    publish('topic', 2);
    setImmediate(() => {
      expect(receiver.mock.calls).toEqual([[1]]);
      done();
    });
  });
});

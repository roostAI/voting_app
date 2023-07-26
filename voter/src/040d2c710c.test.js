// Test generated by RoostGPT for test zb-js-test using AI Type Open AI and AI Model gpt-4

import React from 'react';
import { shallow } from 'enzyme';
import Home from './Home';

describe('Home component', () => {
  let wrapper;
  let instance;

  beforeAll(() => {
    jest.useFakeTimers();
    wrapper = shallow(<Home />);
    instance = wrapper.instance();
  });

  afterEach(() => {
    jest.clearAllTimers();
  });

  test('should clear timeout on unmount', () => {
    instance.componentWillUnmount();
    expect(clearTimeout).toHaveBeenCalledWith(instance.timer);
  });

  test('should not clear timeout if timer is not set', () => {
    instance.timer = null;
    instance.componentWillUnmount();
    expect(clearTimeout).not.toHaveBeenCalled();
  });
});
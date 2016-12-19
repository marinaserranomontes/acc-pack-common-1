const OTKAnalytics = require('opentok-solutions-logging');

// eslint-disable-next-line no-console
const message = messageText => console.log(`otSDK: ${messageText}`);

const error = (errorMessage) => {
  throw new Error(`otSDK: ${errorMessage}`);
};

let analytics = null;

const logVariation = {
  attempt: 'Attempt',
  success: 'Success',
  fail: 'Fail',
};

const logAction = {
  // vars for the analytics logs. Internal use
  clientVersion: 'js-vsol-1.0.0',
  componentId: 'sdkWrapper',
  name: 'guidSdkWrapper',
  init: 'Init',
  bindListeners: 'BindListeners',
  isMe: 'IsMe',
  setInternalListeners: 'setInternalListeners',
  enablePublisherAudio: 'EnablePublisherAudio',
  enablePublisherVideo: 'EnablePublisherVideo',
  enableSubscriberAudio: 'EnableSubscriberAudio',
  enableSubscriberVideo: 'EnableSubscriberVideo',
  publish: 'Publish',
  publishPreview: 'PublishPreview',
  unpublish: 'Unpublish',
  subscribe: 'Subscribe',
  unsubscribe: 'Unsubscribe',
  connect: 'Connect',
  forceDisconnect: 'ForceDisconnect',
  forceUnpublish: 'ForceUnpublish',
  signal: 'Signal',
  disconnect: 'Disconnect'
};

const initLogAnalytics = (source, sessionId, connectionId, apikey) => {
  const otkanalyticsData = {
    clientVersion: 'js-vsol-1.0.0',
    source,
    componentId: 'sdkWrapper',
    name: 'sdkWrapper',
    partnerId: apikey,
  };

  analytics = new OTKAnalytics(otkanalyticsData);

  if (connectionId) {
    const sessionInfo = {
      sessionId,
      connectionId,
      partnerId: apikey,
    };
    analytics.addSessionInfo(sessionInfo);
  }
};


const updateLogAnalytics = (sessionId, connectionId, apiKey) => {
  if (sessionId && connectionId && apiKey) {
    const sessionInfo = {
      sessionId,
      connectionId,
      partnerId: apiKey,
    };
    analytics.addSessionInfo(sessionInfo);
  }
};

const log = (action, variation) => {
  analytics.logEvent({ action, variation });
};


module.exports = {
  message,
  error,
  logAction,
  logVariation,
  initLogAnalytics,
  updateLogAnalytics,
  log,
};


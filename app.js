import { messageBuilder, MESSAGE_TYPES } from './shared/message';

App({
  globalData: {
    messageBuilder: messageBuilder,
    MESSAGE_TYPES: MESSAGE_TYPES
  },
  onCreate(options) {
    console.log("app on create invoke");
  },

  onDestroy(options) {
    console.log("app on destroy invoke");
  },
});

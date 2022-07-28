import { NativeModules } from 'react-native';

console.log(NativeModules.CallManager);
console.log(NativeModules.CallEventEmitter);
console.log(NativeModules.CallViewManager);
console.log(NativeModules.WebexManager);
export default NativeModules.CallEventEmitter;

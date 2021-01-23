import {BleManager} from 'react-native-ble-plx';
import {PermissionsAndroid} from 'react-native';
import base64 from 'react-native-base64';

export default class BLE {
  constructor(ping_frequency, sampling_frequency) {
    this.manager = new BleManager();
    this.setPing(ping_frequency);
    this.sampling_frequency =
      sampling_frequency === undefined ? 1 : sampling_frequency;
    this.manager.setLogLevel('Verbose');
    this.uuids = ['6e400001-b5a3-f393-e0a9-e50e24dcca9e'];
    this.checkConnection(this.connectionCallback);
    // console.log(this);
  }

  connectionCallback(on, connected) {
    if (!on) {
      alert('Please turn on bluetooth from settings');
    } else if (!connected) {
      alert('Connection lost with gravity device');
      this.checkConnection(this.connectionCallback);
    } else {
    }
  }

  setPing(ping_frequency) {
    this.ping_frequency = ping_frequency === undefined ? 1000 : ping_frequency;
  }

  disconnect() {
    // if (this.device) this.device.cancelConnection();
    // this.manager.destroy();
    console.log('disconnected');
  }

  send() {}

  async request() {
    const newdevice = await this.device.discoverAllServicesAndCharacteristics();
    const services = await newdevice.services();
    if (!services) throw 'no services found';
    const characteristics = await newdevice.characteristicsForService(
      services[0].uuid,
    );
    if (!characteristics) throw 'no characteristics found';
    const characteristic = await this.manager.readCharacteristicForDevice(
      newdevice.id,
      services[0].uuid,
      characteristics[0].uuid,
    );
    var decodedString = base64.decode(characteristic.value);
    console.log('data from ble: ' + decodedString);
    return decodedString;
    //console.log(services[0].id, characteristics[0].id, characteristics[0]);
    /*  const characteristic = await newdevice.readCharacteristicForService(
      services[0].uuid,
      characteristics[0].uuid,
    ); */
  }

  requestCameraPermission = async (callback) => {
    try {
      const granted = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        'android.permission.ACCESS_BACKGROUND_LOCATION',
      ]);
      if (
        granted[PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION] ===
        PermissionsAndroid.RESULTS.GRANTED
      ) {
        this.checkConnection(callback);
      } else {
        console.log('permission denied');
      }
    } catch (err) {
      console.warn(err);
    }
  };

  async disconnectCallback(errro, device, manager) {
    this.connected = false;
    let state = await manager.state();
    if (state === 'PoweredOn') {
      this.connectionCallback(true, false);
    }
    console.log('device disconnected, ' + state + ', ' + error);
  }

  checkConnection(callback) {
    if (this.subscription) this.subscription.remove();
    this.subscription = this.manager.onStateChange((state) => {
      this.state = state;
      if (state === 'PoweredOn') {
        this.manager.startDeviceScan(
          null,
          {allowDuplicates: true},
          (error, device) => {
            if (error) {
              if (
                error.message === 'Device is not authorized to use BluetoothLE'
              ) {
                this.requestCameraPermission(callback);
              }
              console.log(error);
              return;
            }
            //console.log(device.name);
            if (device.name === 'Gravity') {
              // console.log(device.name);
              if (this.device)
                this.device.isConnected().then((connected) => {
                  if (!connected)
                    device
                      .connect()
                      .then(async (device_) => {
                        this.connected = await device_.isConnected();
                        this.device = device_;
                        device_.onDisconnected((error, device) =>
                          this.disconnectCallback(error, device, this.manager),
                        );
                        callback(true, this.connected);
                      })
                      .catch((err) => {
                        console.log(err);
                      });
                  else {
                    this.connected = true;
                  }
                });
              else {
                device
                  .connect()
                  .then(async (device_) => {
                    this.connected = await device_.isConnected();
                    this.device = device_;
                    device_.onDisconnected((error, device) =>
                      this.disconnectCallback(error, device, this.manager),
                    );
                    callback(true, this.connected);
                  })
                  .catch((err) => {
                    console.log('device: ' + err);
                  });
              }
              this.manager.stopDeviceScan();
            }
          },
        );
        // subscription.remove();
      } else if (state === 'PoweredOff') {
        this.connected = false;
        callback(false, false);
      } else {
        this.connected = false;
      }
    }, true);
  }
}

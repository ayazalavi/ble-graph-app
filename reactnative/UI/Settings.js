import React, {useState} from 'react';
import {Text, Button, View, TextInput, TouchableOpacity} from 'react-native';
import {settings} from '../modules/styles';
import {
  getData,
  storeData,
  SAMPLE_KEY,
  PING_KEY,
  DATA_POINTS_KEY,
} from '../modules/DataModule';
import Icon from 'react-native-vector-icons/Ionicons';

const SettingsScreen = ({navigation, route}) => {
  React.useLayoutEffect(() => {
    getData(SAMPLE_KEY).then((value) => {
      if (value) setSampling(parseFloat(value));
    });
    getData(PING_KEY).then((value) => {
      if (value) setPing(parseFloat(value));
    });
    getData(DATA_POINTS_KEY).then((value) => {
      if (value) setDataPoints(parseInt(value));
    });
    navigation.setOptions({
      headerLeft: () => (
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Icon name="chevron-back-outline" size={40} color="#ffffff" />
        </TouchableOpacity>
      ),
    });
  }, [navigation]);
  const [sampling, setSampling] = useState(1);
  const [ping, setPing] = useState(1000);
  const [dataPoints, setDataPoints] = useState(10);
  const updateStorage = (e) => {
    if (!ping || !sampling || !dataPoints) {
      alert(
        'Please enter ping value, number of data points and sample frequency both.',
      );
      return false;
    }
    Promise.all([
      storeData(SAMPLE_KEY, `${sampling}`),
      storeData(PING_KEY, `${ping}`),
      storeData(DATA_POINTS_KEY, `${dataPoints}`),
    ]).then((messages) => {
      alert('data saved');
    });
  };
  return (
    <View style={settings.mainview}>
      <Input
        placeholder={'Sampling frequency'}
        keyboardType="decimal-pad"
        value={`${sampling}`}
        title="Enter sampling frequency from 1 to 50"
        onChange={(e) => {
          let sample_ = parseFloat(e.nativeEvent.text);
          if (!sample_ || sample_ < 1 || sample_ > 50) return false;
          setSampling(sample_);
        }}
      />
      <Input
        placeholder={'BLE ping frequency'}
        keyboardType="decimal-pad"
        value={`${ping}`}
        title="Enter ping frequency in millis"
        onChange={(e) => {
          const ping_ = parseFloat(e.nativeEvent.text);
          if (!ping_ || ping_ < 1) return false;
          setPing(ping_);
        }}
      />
      <Input
        placeholder={'Number of data points to plot'}
        keyboardType="decimal-pad"
        value={`${dataPoints}`}
        title="Enter number of data points to plot in graph view"
        onChange={(e) => {
          const datapoints_ = parseFloat(e.nativeEvent.text);
          if (!datapoints_ || datapoints_ < 1) return false;
          setDataPoints(datapoints_);
        }}
      />
      <AppButton
        title="Update"
        size="sm"
        backgroundColor="#007bff"
        onPress={updateStorage}
        style={settings.updateButton}
      />
    </View>
  );
};

const AppButton = ({onPress, title, size, backgroundColor}) => (
  <TouchableOpacity onPress={onPress} style={settings.appButtonContainer}>
    <Text style={[settings.appButtonText, size === 'sm' && {fontSize: 14}]}>
      {title}
    </Text>
  </TouchableOpacity>
);

const Input = (props) => {
  return (
    <>
      <Text style={settings.labelText}>{props.title}</Text>
      <TextInput {...props} style={settings.textbox} />
    </>
  );
};

export default SettingsScreen;

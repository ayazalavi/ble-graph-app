import {StyleSheet} from 'react-native';

export const graphStyles = StyleSheet.create({
  buttonStack: {
    flexDirection: 'row',
  },
  buttonType: {
    flex: 1,
    backgroundColor: 'blue',
    color: 'white',
    paddingVertical: 10,
    paddingHorizontal: 0,
    borderRadius: 0,
  },
  buttonType1: {
    color: 'white',
    fontSize: 10,
  },
  buttonSelected: {
    flex: 1,
    backgroundColor: 'darkblue',
    color: 'white',
    paddingVertical: 10,
    paddingHorizontal: 0,
    borderRadius: 0,
  },
  appButtonText: {
    fontSize: 12,
    color: 'white',
    alignSelf: 'center',
    textTransform: 'uppercase',
  },
});

export const list = StyleSheet.create({
  main: {
    flexDirection: 'row',
    borderBottomColor: 'orange',
    borderBottomWidth: 1,
  },
  child: {
    flex: 1,
    textAlign: 'center',
    borderBottomColor: 'orange',
    borderBottomWidth: 1,
    color: 'orange',
  },
  childheader: {
    flex: 1,
    textAlign: 'center',
    color: 'white',
    fontSize: 16,
  },
  mainheader: {
    flexDirection: 'row',
    backgroundColor: 'orange',
  },
});

export const settings = StyleSheet.create({
  textbox: {
    borderColor: 'orange',
    borderWidth: 1,
    margin: 15,
    color: 'orange',
    height: 50,
    padding: 10,
  },
  updateButton: {
    margin: 15,
    width: '50%',
    backgroundColor: 'white',
    color: 'white',
  },
  mainview: {
    backgroundColor: 'white',
    flex: 1,
    paddingVertical: 15,
  },
  screenContainer: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
  },
  appButtonContainer: {
    elevation: 8,
    backgroundColor: 'orange',
    paddingVertical: 10,
    paddingHorizontal: 12,
    margin: 15,
  },
  appButtonText: {
    fontSize: 18,
    color: 'white',
    fontWeight: 'bold',
    alignSelf: 'center',
    textTransform: 'uppercase',
  },
  labelText: {
    fontSize: 18,
    color: 'orange',
    marginHorizontal: 15,
  },
});

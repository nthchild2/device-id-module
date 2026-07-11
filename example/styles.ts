import { StyleSheet } from 'react-native';

export const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#eee',
    paddingTop: 80,
    paddingHorizontal: 20,
  },
  header: {
    fontSize: 30,
    marginBottom: 20,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  identifier: {
    fontSize: 16,
    fontVariant: ['tabular-nums'],
  },
  errorCode: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#b00020',
    marginBottom: 4,
  },
  errorMessage: {
    fontSize: 14,
    color: '#b00020',
  },
});

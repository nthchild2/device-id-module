import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Button, Text, View } from 'react-native';
import FintechSecurity from 'fintech-security';

import { styles } from './styles';

type IdentifierState =
  | { status: 'loading' }
  | { status: 'success'; id: string }
  | { status: 'error'; code: string; message: string };

export default function App() {
  const [state, setState] = useState<IdentifierState>({ status: 'loading' });

  const loadIdentifier = useCallback(async () => {
    setState({ status: 'loading' });
    try {
      const id = await FintechSecurity.getIdentifier();
      setState({ status: 'success', id });
    } catch (error) {
      const { code, message } = error as Error & { code?: string };
      setState({ status: 'error', code: code ?? 'UNKNOWN', message });
    }
  }, []);

  useEffect(() => {
    loadIdentifier();
  }, [loadIdentifier]);

  return (
    <View style={styles.container}>
      <Text style={styles.header}>FintechSecurity</Text>
      <View style={styles.card}>
        <Text style={styles.label}>Device identifier</Text>
        {state.status === 'loading' && <ActivityIndicator />}
        {state.status === 'success' && (
          <Text selectable style={styles.identifier}>
            {state.id}
          </Text>
        )}
        {state.status === 'error' && (
          <>
            <Text style={styles.errorCode}>{state.code}</Text>
            <Text style={styles.errorMessage}>{state.message}</Text>
          </>
        )}
      </View>
      <Button title="Reload" onPress={loadIdentifier} />
    </View>
  );
}

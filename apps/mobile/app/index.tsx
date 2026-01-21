import { useEffect, useState } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuthStore } from '../src/store/authStore';

export default function Index() {
  const router = useRouter();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    // Wait for hydration or other checks
    const timer = setTimeout(() => {
        setReady(true);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (!ready) return;
    
    if (isAuthenticated) {
      router.replace('/home');
    } else {
      router.replace('/login');
    }
  }, [ready, isAuthenticated, router]);

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <ActivityIndicator size="large" />
    </View>
  );
}

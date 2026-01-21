import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuthStore } from '../src/store/authStore';
import api from '../src/services/api';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const login = useAuthStore((state) => state.login);

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Por favor ingresa email y contraseña');
      return;
    }

    setLoading(true);
    try {
      // Endpoint hardcoded for now based on Auth Service
      const response = await api.post('/api/auth/token/', {
        username: email, // Django uses username usually, but we might have email as username
        password: password
      });

      const { access, refresh } = response.data;
      
      // Fake user data for now or fetch from /api/users/me/
      login(access, { email });
      
      Alert.alert('Exito', 'Bienvenido');
      router.replace('/home'); 
    } catch (error: any) {
      console.error(error);
      Alert.alert('Error de Login', error.response?.data?.detail || 'No se pudo conectar');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
        <Text style={styles.title}>Gym Tracker</Text>
        <Text style={styles.subtitle}>Inicia Sesión</Text>
        
        <TextInput
            style={styles.input}
            placeholder="Email / Usuario"
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
        />
        
        <TextInput
            style={styles.input}
            placeholder="Contraseña"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
        />
        
        {loading ? (
            <ActivityIndicator size="large" color="#0000ff" />
        ) : (
            <Button title="Ingresar" onPress={handleLogin} />
        )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
    color: '#333',
  },
  subtitle: {
      fontSize: 18,
      textAlign: 'center',
      marginBottom: 30,
      color: '#666',
  },
  input: {
    height: 50,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 8,
    marginBottom: 15,
    paddingHorizontal: 15,
    fontSize: 16,
  },
});

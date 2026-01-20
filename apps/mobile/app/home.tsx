import { View, Text, StyleSheet, Button } from 'react-native';
import { useAuthStore } from '../src/store/authStore';
import { useRouter } from 'expo-router';

export default function HomeScreen() {
    const logout = useAuthStore((state) => state.logout);
    const user = useAuthStore((state) => state.user);
    const router = useRouter();

    const handleLogout = () => {
        logout();
        router.replace('/login');
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Bienvenido, {user?.email}</Text>
            <Text style={styles.text}>Aquí verás tus rutinas asignadas.</Text>
            
            <View style={styles.spacer} />
            
            <Button title="Cerrar Sesión" onPress={handleLogout} color="red" />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
    },
    title: {
        fontSize: 24,
        fontWeight: 'bold',
        marginBottom: 10,
    },
    text: {
        fontSize: 16,
        color: '#555',
    },
    spacer: {
        height: 50,
    }
});

import requests
from config import API_BASE_URL, ENDPOINTS

class GymTrackerClient:
    def __init__(self):
        self.token = None
        self.base_url = API_BASE_URL.rstrip('/')

    def login(self, username, password):
        url = f"{self.base_url}{ENDPOINTS['login']}"
        try:
            response = requests.post(url, json={"username": username, "password": password}, timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access")
                return True, "Login exitoso"
            else:
                return False, f"Error {response.status_code}: {response.text}"
        except Exception as e:
            return False, f"Error de conexión: {str(e)}"

    def get_headers(self):
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def get_groups(self):
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}{ENDPOINTS['groups']}"
        try:
            response = requests.get(url, headers=self.get_headers())
            if response.status_code == 200:
                return True, response.json()
            return False, response.text
        except Exception as e:
            return False, str(e)

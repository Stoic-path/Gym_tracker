import requests
import re
import json
import html
from config import API_BASE_URL, ENDPOINTS

class GymTrackerClient:
    def __init__(self):
        self.token = None
        self.base_url = API_BASE_URL.rstrip('/')

    def _safe_error_message(self, response):
        content_type = response.headers.get("Content-Type", "")
        if "application/json" in content_type:
            try:
                data = response.json()
                return json.dumps(data)
            except Exception:
                pass

        text = response.text or ""
        if "<html" in text.lower():
            text = re.sub(r"(?is)<style.*?>.*?</style>", " ", text)
            text = re.sub(r"(?is)<script.*?>.*?</script>", " ", text)
        text = re.sub(r"<[^>]+>", " ", text)
        text = html.unescape(text)
        text = re.sub(r"\s+", " ", text).strip()

        if "ValueError" in text:
            match = re.search(r"ValueError[^.]*", text)
            if match:
                return match.group(0).strip()

        return (text[:200] + "...") if len(text) > 200 else text or "Server error."

    def login(self, username, password):
        url = f"{self.base_url}{ENDPOINTS['login']}"
        try:
            response = requests.post(url, json={"email": username, "password": password}, timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access")
                return True, "Login exitoso"
            else:
                return False, f"Error {response.status_code}: {self._safe_error_message(response)}"
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
            return False, self._safe_error_message(response)
        except Exception as e:
            return False, str(e)

    def get_group_details(self, group_id):
        """Obtiene detalles de un Grupo Muscular específico (incluyendo subgrupos)"""
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}{ENDPOINTS['groups']}{group_id}/"
        try:
            response = requests.get(url, headers=self.get_headers())
            if response.status_code == 200:
                return True, response.json()
            return False, self._safe_error_message(response)
        except Exception as e:
            return False, str(e)

    def update_group(self, group_id, group_data):
        """Actualiza la estructura completa del grupo (añadir ejercicios/subgrupos)"""
        """NOTA: group_id debe ser un UUID válido"""
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}{ENDPOINTS['groups']}{group_id}/"
        try:
            # PUT para reemplazo completo
            response = requests.put(url, json=group_data, headers=self.get_headers())
            if response.status_code in [200, 204]:
                return True, response.json() if response.content else "OK"
            return False, f"Error {response.status_code}: {self._safe_error_message(response)}"
        except Exception as e:
            return False, str(e)

    def get_presigned_url(self, file_name, file_type):
        """Solicita una URL temporal para subir archivos a S3"""
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}/api/exercises/upload-url/"
        payload = {"file_name": file_name, "file_type": file_type}
        try:
            response = requests.post(url, json=payload, headers=self.get_headers())
            if response.status_code == 200:
                return True, response.json() # { "upload_url": ..., "public_url": ... }
            return False, self._safe_error_message(response)
        except Exception as e:
            return False, str(e)

    def get_routines(self):
        """Obtiene todas las rutinas visibles (propias + públicas)"""
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}{ENDPOINTS['routines']}"
        try:
            response = requests.get(url, headers=self.get_headers())
            if response.status_code == 200:
                return True, response.json()
            return False, self._safe_error_message(response)
        except Exception as e:
            return False, str(e)

    def create_routine(self, routine_data):
        """Crea una nueva rutina (puede ser pública)"""
        if not self.token: return False, "No autenticado"
        url = f"{self.base_url}{ENDPOINTS['routines']}"
        # Asegurar is_public=True si es admin (aunque se pase en data)
        try:
            response = requests.post(url, json=routine_data, headers=self.get_headers())
            if response.status_code in [200, 201]:
                return True, response.json()
            return False, f"Error {response.status_code}: {self._safe_error_message(response)}"
        except Exception as e:
            return False, str(e)


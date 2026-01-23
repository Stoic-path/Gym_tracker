import requests
import os
import mimetypes

class S3Uploader:
    def __init__(self, api_client):
        self.client = api_client

    def upload_video(self, file_path):
        """
        Sube un video a S3 usando una Presigned URL obtenida del Backend.
        Esto evita necesitar credenciales de AWS en la máquina del cliente desktop.
        """
        if not os.path.isfile(file_path):
            return False, "El archivo no existe."

        file_name = os.path.basename(file_path)
        # Adivinar tipo MIME (video/mp4, etc.)
        content_type, _ = mimetypes.guess_type(file_path)
        if not content_type: content_type = 'application/octet-stream'

        # 1. Obtener URL firmada
        success, data = self.client.get_presigned_url(file_name, content_type)
        if not success:
            return False, f"Error obteniendo URL de subida: {data}"

        upload_url = data.get('upload_url')
        public_url = data.get('public_url')
        
        if not upload_url:
            return False, "Backend no retornó upload_url"

        # 2. Subir archivo directamente a S3
        try:
            with open(file_path, 'rb') as f:
                # PUT request directo a S3 con el contenido binario
                headers = {'Content-Type': content_type}
                response = requests.put(upload_url, data=f, headers=headers)
                
            if response.status_code == 200:
                return True, public_url
            else:
                return False, f"Error S3 ({response.status_code}): {response.text}"
        except Exception as e:
            return False, f"Error subiendo archivo: {str(e)}"

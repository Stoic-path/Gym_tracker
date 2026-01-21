import boto3
import os
from botocore.exceptions import NoCredentialsError
from config import AWS_REGION, S3_BUCKET_NAME

class S3Uploader:
    def __init__(self):
        self.bucket_name = S3_BUCKET_NAME
        # boto3 buscará automáticamente las credenciales en las variables de entorno
        # o en el archivo ~/.aws/credentials configurado por switch_account.ps1
        self.s3 = boto3.client('s3', region_name=AWS_REGION)

    def upload_video(self, file_path):
        """Sube un video a S3 y retorna la URL pública"""
        if not os.path.isfile(file_path):
            return False, "El archivo no existe."

        file_name = os.path.basename(file_path)
        # Usamos una carpeta 'exercises' dentro del bucket para organizar
        object_name = f"exercises/{file_name}"

        try:
            self.s3.upload_file(file_path, self.bucket_name, object_name)
            # Construimos la URL manualmente (asumiendo acceso público o presigned en el futuro)
            url = f"https://{self.bucket_name}.s3.amazonaws.com/{object_name}"
            return True, url
        except NoCredentialsError:
            return False, "No se encontraron credenciales de AWS."
        except Exception as e:
            return False, f"Error S3: {str(e)}"
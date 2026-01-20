import customtkinter as ctk
import threading
from tkinter import filedialog, simpledialog
import os
import json
from api_client import GymTrackerClient
from s3_client import S3Uploader
from config import API_BASE_URL

ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class AdminApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Gym Tracker Admin - Rutinas y Ejercicios")
        self.geometry("1100x700")
        self.client = GymTrackerClient()
        self.s3 = S3Uploader()
        
        # Estado de la aplicacion
        self.current_groups = []
        self.selected_group = None
        self.selected_subgroup = None

        # Verificar configuración
        if "REEMPLAZAR" in API_BASE_URL:
            self.show_error_screen("Por favor actualiza API_BASE_URL en config.py\ncon el DNS de tu Load Balancer.")
        else:
            self.show_login_screen()

    def show_error_screen(self, message):
        self.clear_screen()
        label = ctk.CTkLabel(self, text=message, text_color="red", font=("Arial", 16))
        label.pack(pady=50)

    def clear_screen(self):
        for widget in self.winfo_children():
            widget.destroy()

    def show_login_screen(self):
        self.clear_screen()

        frame = ctk.CTkFrame(self)
        frame.pack(pady=40, padx=40, fill="both", expand=True)

        ctk.CTkLabel(frame, text="Admin Login", font=("Roboto", 24)).pack(pady=12)

        self.entry_user = ctk.CTkEntry(frame, placeholder_text="Email")
        self.entry_user.pack(pady=12)

        self.entry_pass = ctk.CTkEntry(frame, placeholder_text="Password", show="*")
        self.entry_pass.pack(pady=12)

        ctk.CTkButton(frame, text="Ingresar", command=self.login_event).pack(pady=12)

        self.lbl_status = ctk.CTkLabel(frame, text="")
        self.lbl_status.pack(pady=10)

    def login_event(self):
        user = self.entry_user.get()
        password = self.entry_pass.get()
        
        self.lbl_status.configure(text="Conectando...", text_color="yellow")
        self.update()

        success, message = self.client.login(user, password)
        
        if success:
            self.lbl_status.configure(text="Éxito!", text_color="green")
            self.after(500, self.load_data_and_show_dashboard)
        else:
            self.lbl_status.configure(text=f"Error: {message}", text_color="red")

    def load_data_and_show_dashboard(self):
        # Pantalla de carga
        self.lbl_status.configure(text="Cargando grupos...", text_color="blue")
        success, data = self.client.get_groups()
        
        if success:
            self.current_groups = data
            self.show_dashboard()
        else:
            self.lbl_status.configure(text=f"Error cargando datos: {data}", text_color="red")

    # --- DASHBOARD PRINCIPAL ---
    def show_dashboard(self):
        self.clear_screen()
        
        # 1. HEADER
        header = ctk.CTkFrame(self, height=50)
        header.pack(fill="x", padx=10, pady=5)
        ctk.CTkLabel(header, text="Gestor de Rutinas y Ejercicios", font=("Roboto", 18, "bold")).pack(side="left", padx=20)
        ctk.CTkButton(header, text="Refrescar", width=100, command=self.refresh_data).pack(side="right", padx=10)
        ctk.CTkButton(header, text="Salir", width=80, fg_color="red", command=self.logout).pack(side="right", padx=10)

        # 2. CONTENIDO (3 Columnas)
        content = ctk.CTkFrame(self)
        content.pack(fill="both", expand=True, padx=10, pady=5)

        # Columna 1: Grupos Musculares (Colores)
        col1 = ctk.CTkFrame(content, width=250)
        col1.pack(side="left", fill="both", padx=5, pady=5)
        
        # Titulo y boton de agregar
        header_col1 = ctk.CTkFrame(col1)
        header_col1.pack(fill="x", padx=5, pady=5)
        ctk.CTkLabel(header_col1, text="1. Grupos (Colores)", font=("Roboto", 14, "bold")).pack(side="left")
        
        self.scroll_groups = ctk.CTkScrollableFrame(col1)
        self.scroll_groups.pack(fill="both", expand=True, padx=5, pady=5)
        
        self.populate_groups_list()

        # Columna 2: Subgrupos (Partes del cuerpo)
        col2 = ctk.CTkFrame(content, width=300)
        col2.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        self.lbl_subgroup_title = ctk.CTkLabel(col2, text="2. Subgrupos", font=("Roboto", 14, "bold"))
        self.lbl_subgroup_title.pack(pady=5)

        self.scroll_subgroups = ctk.CTkScrollableFrame(col2)
        self.scroll_subgroups.pack(fill="both", expand=True, padx=5, pady=5)
        
        self.btn_add_subgroup = ctk.CTkButton(col2, text="+ Subgrupo", command=self.add_subgroup, state="disabled")
        self.btn_add_subgroup.pack(pady=10)

        # Columna 3: Ejercicios
        col3 = ctk.CTkFrame(content, width=400)
        col3.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        self.lbl_exercise_title = ctk.CTkLabel(col3, text="3. Ejercicios", font=("Roboto", 14, "bold"))
        self.lbl_exercise_title.pack(pady=5)

        self.scroll_exercises = ctk.CTkScrollableFrame(col3)
        self.scroll_exercises.pack(fill="both", expand=True, padx=5, pady=5)
        
        self.btn_add_exercise = ctk.CTkButton(col3, text="+ Ejercicio (Video S3)", command=self.show_add_exercise_dialog, state="disabled")
        self.btn_add_exercise.pack(pady=10)

    def populate_groups_list(self):
        for widget in self.scroll_groups.winfo_children(): widget.destroy()
        
        for group in self.current_groups:
            # Intentar obtener 'id' o 'uid'
            group_id = group.get('id') or group.get('uid')
            color = group.get('color', '?')
            name = group.get('name', 'Sin Nombre')
            
            btn = ctk.CTkButton(self.scroll_groups, 
                                text=f"{name} ({color})", 
                                fg_color="transparent", 
                                border_width=1,
                                command=lambda g=group: self.select_group(g))
            btn.pack(fill="x", pady=2)

    def select_group(self, group):
        self.selected_group = group
        self.selected_subgroup = None
        self.lbl_subgroup_title.configure(text=f"Subgrupos de: {group.get('name')}")
        self.btn_add_subgroup.configure(state="normal")
        
        # Limpiar ejercicios
        for w in self.scroll_exercises.winfo_children(): w.destroy()
        self.btn_add_exercise.configure(state="disabled")

        # Llenar Subgrupos
        for widget in self.scroll_subgroups.winfo_children(): widget.destroy()
        
        subgroups = group.get('subgroups', [])
        for sub in subgroups:
            count = len(sub.get('exercises', []))
            btn = ctk.CTkButton(self.scroll_subgroups,
                                text=f"{sub.get('name')} ({count} ej.)",
                                fg_color="gray",
                                command=lambda s=sub: self.select_subgroup(s))
            btn.pack(fill="x", pady=2)

    def select_subgroup(self, subgroup):
        self.selected_subgroup = subgroup
        self.lbl_exercise_title.configure(text=f"Ejercicios de: {subgroup.get('name')}")
        self.btn_add_exercise.configure(state="normal")

        # Llenar Ejercicios
        for widget in self.scroll_exercises.winfo_children(): widget.destroy()
        
        exercises = subgroup.get('exercises', [])
        for ex in exercises:
            frame = ctk.CTkFrame(self.scroll_exercises)
            frame.pack(fill="x", pady=2)
            
            ctk.CTkLabel(frame, text=ex.get('name'), font=("Roboto", 12, "bold")).pack(anchor="w", padx=5)
            
            has_video = bool(ex.get('short_video_url'))
            url_text = "📹 Video OK" if has_video else "❌ Sin video"
            color = "green" if has_video else "orange"
            ctk.CTkLabel(frame, text=url_text, text_color=color, font=("Roboto", 10)).pack(anchor="w", padx=5)

    # --- LOGICA DE ACTUALIZACIÓN ---
    def add_subgroup(self):
        dialog = ctk.CTkInputDialog(text="Nombre del nuevo Subgrupo:", title="Nuevo Subgrupo")
        name = dialog.get_input()
        if not name: return

        # Estructura del nuevo subgrupo (comprobar modelo backend)
        new_sub = {
            "name": name,
            "min_exercises": 2,
            "max_exercises": 3,
            "exercises": []
        }
        
        # Modificar localmente
        if 'subgroups' not in self.selected_group:
            self.selected_group['subgroups'] = []
            
        self.selected_group['subgroups'].append(new_sub)
        
        # Guardar en Backend
        self.save_group_changes()

    def show_add_exercise_dialog(self):
        # Crear ventana modal simple
        self.top = ctk.CTkToplevel(self)
        self.top.geometry("400x400")
        self.top.title("Nuevo Ejercicio")
        self.top.attributes("-topmost", True)

        ctk.CTkLabel(self.top, text="Nombre del Ejercicio").pack(pady=5)
        entry_name = ctk.CTkEntry(self.top)
        entry_name.pack(pady=5)

        ctk.CTkLabel(self.top, text="Video MP4").pack(pady=5)
        path_label = ctk.CTkLabel(self.top, text="...", text_color="gray")
        path_label.pack(pady=5)
        
        def select_vid():
            p = filedialog.askopenfilename(filetypes=[("Video", "*.mp4 *.mov *.mkv *.avi")])
            if p: path_label.configure(text=p)
        
        ctk.CTkButton(self.top, text="Elegir Archivo", command=select_vid).pack(pady=5)
        
        status_lbl = ctk.CTkLabel(self.top, text="")
        status_lbl.pack(pady=5)

        def save():
            name = entry_name.get()
            path = path_label.cget("text")
            
            if not name or not os.path.isfile(path):
                status_lbl.configure(text="Faltan datos", text_color="red")
                return

            status_lbl.configure(text="Subiendo a S3...", text_color="blue")
            self.top.update()

            # Subir
            threading.Thread(target=self._bg_upload, args=(name, path, status_lbl)).start()

        ctk.CTkButton(self.top, text="Guardar", command=save, fg_color="green").pack(pady=20)
        self.top.wait_window()

    def _bg_upload(self, name, path, lbl):
        ok, url = self.s3.upload_video(path)
        if not ok:
            lbl.configure(text=f"Error S3: {url}", text_color="red")
            return
        
        lbl.configure(text="Guardando...", text_color="blue")
        
        # Estructura Exercise serializada
        new_exercise = {
            "name": name,
            "short_video_url": url,
            "description": "Subido desde Desktop Admin",
            "needs_weight": True
        }

        # Actualizar estructura anidada localmente
        # Buscamos el subgrupo correcto dentro del grupo seleccionado
        # OJO: select_subgroup tiene una referencia, pero al reconstruir el JSON
        # necesitamos asegurarnos de que estamos modificando la lista
        target_found = False
        
        for sub in self.selected_group['subgroups']:
            if sub['name'] == self.selected_subgroup['name']: # Usamos nombre como ID temporal
                if 'exercises' not in sub:
                     sub['exercises'] = []
                sub['exercises'].append(new_exercise)
                target_found = True
                break
        
        if target_found:
            self.save_group_changes(lbl)
        else:
            lbl.configure(text="Error interno: Subgrupo no encontrado", text_color="red")

    def save_group_changes(self, label_widget=None):
        """Envía el JSON completo del grupo actualizado al backend"""
        pk = self.selected_group.get('id') or self.selected_group.get('uid')

        success, msg = self.client.update_group(pk, self.selected_group)
        
        if label_widget:
            if success:
                label_widget.configure(text="¡Guardado!", text_color="green")
                self.after(1000, self.top.destroy)
                self.refresh_data()
            else:
                label_widget.configure(text=f"Error Backend: {msg}", text_color="red")
        else:
            if success:
                self.refresh_data()
            else:
                print(f"Error saving: {msg}")

    def refresh_data(self):
        self.load_data_and_show_dashboard()

    def logout(self):
        self.client.token = None
        self.show_login_screen()

if __name__ == "__main__":
    app = AdminApp()
    app.mainloop()

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
        # Inyectamos el cliente API para obtener la URL firmada
        self.s3 = S3Uploader(self.client)
        
        # Estado de la aplicacion
        self.current_groups = []
        self.current_routines = []  # Cache de rutinas
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
        self.lbl_status.configure(text="Cargando datos...", text_color="blue")
        self.update() # Force UI update
        
        # Cargar Grupos (Ejercicios)
        ok1, data1 = self.client.get_groups()
        # Cargar Rutinas
        ok2, data2 = self.client.get_routines()

        if ok1:
            self.current_groups = data1
            if ok2: 
                self.current_routines = data2
            else:
                self.lbl_status.configure(text=f"Rutinas error: {str(data2)[:50]}...", text_color="orange")
                print(f"Full Routine Error: {data2}")
            
            self.show_dashboard()
        else:
            self.lbl_status.configure(text=f"Error cargando grupos: {data1}", text_color="red")

    # --- DASHBOARD PRINCIPAL (CON TABS) ---
    def show_dashboard(self):
        self.clear_screen()
        
        # 1. HEADER
        header = ctk.CTkFrame(self, height=50)
        header.pack(fill="x", padx=10, pady=5)
        ctk.CTkLabel(header, text="Admin Panel - Gym Tracker", font=("Roboto", 18, "bold")).pack(side="left", padx=20)
        ctk.CTkButton(header, text="Refrescar", width=100, command=self.refresh_data).pack(side="right", padx=10)
        ctk.CTkButton(header, text="Salir", width=80, fg_color="red", command=self.logout).pack(side="right", padx=10)

        # 2. TAB VIEW
        self.tabview = ctk.CTkTabview(self)
        self.tabview.pack(fill="both", expand=True, padx=10, pady=5)

        self.tab_exercises = self.tabview.add("Biblioteca de Ejercicios")
        self.tab_routines = self.tabview.add("Gestor de Rutinas")

        # --- TAB 1: EJERCICIOS (Tu codigo anterior) ---
        self.build_exercises_tab(self.tab_exercises)

        # --- TAB 2: RUTINAS (Nuevo) ---
        self.build_routines_tab(self.tab_routines)

    def build_exercises_tab(self, parent):
        # Columna 1: Grupos Musculares (Colores)
        col1 = ctk.CTkFrame(parent, width=250)
        col1.pack(side="left", fill="both", padx=5, pady=5)
        
        header_col1 = ctk.CTkFrame(col1)
        header_col1.pack(fill="x", padx=5, pady=5)
        ctk.CTkLabel(header_col1, text="1. Grupos", font=("Roboto", 14, "bold")).pack(side="left")
        
        self.scroll_groups = ctk.CTkScrollableFrame(col1)
        self.scroll_groups.pack(fill="both", expand=True, padx=5, pady=5)
        self.populate_groups_list() # Usa self.scroll_groups

        # Columna 2: Subgrupos
        col2 = ctk.CTkFrame(parent, width=300)
        col2.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        self.lbl_subgroup_title = ctk.CTkLabel(col2, text="2. Subgrupos", font=("Roboto", 14, "bold"))
        self.lbl_subgroup_title.pack(pady=5)

        self.scroll_subgroups = ctk.CTkScrollableFrame(col2)
        self.scroll_subgroups.pack(fill="both", expand=True, padx=5, pady=5)
        self.btn_add_subgroup = ctk.CTkButton(col2, text="+ Subgrupo", command=self.add_subgroup, state="disabled")
        self.btn_add_subgroup.pack(pady=10)

        # Columna 3: Ejercicios
        col3 = ctk.CTkFrame(parent, width=400)
        col3.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        self.lbl_exercise_title = ctk.CTkLabel(col3, text="3. Ejercicios", font=("Roboto", 14, "bold"))
        self.lbl_exercise_title.pack(pady=5)

        self.scroll_exercises = ctk.CTkScrollableFrame(col3)
        self.scroll_exercises.pack(fill="both", expand=True, padx=5, pady=5)
        self.btn_add_exercise = ctk.CTkButton(col3, text="+ Ejercicio (Video)", command=self.show_add_exercise_dialog, state="disabled")
        self.btn_add_exercise.pack(pady=10)

    def build_routines_tab(self, parent):
        # Panel Izquierdo: Lista de Rutinas
        left_panel = ctk.CTkFrame(parent, width=300)
        left_panel.pack(side="left", fill="y", padx=10, pady=10)
        
        ctk.CTkLabel(left_panel, text="Rutinas Públicas", font=("Roboto", 16, "bold")).pack(pady=10)
        ctk.CTkButton(left_panel, text="+ Nueva Rutina", fg_color="green", command=self.show_create_routine_dialog).pack(pady=5)
        
        self.scroll_routines = ctk.CTkScrollableFrame(left_panel)
        self.scroll_routines.pack(fill="both", expand=True, pady=10)
        
        # Llenar lista
        for r in self.current_routines:
            text = f"{r['name']} ({len(r.get('groups', []))} grupos)"
            if r.get('is_public'): text += " 🌍"
            ctk.CTkButton(self.scroll_routines, text=text, fg_color="gray", command=lambda x=r: self.show_routine_details(x)).pack(fill="x", pady=2)

        # Panel Derecho: Detalles
        self.right_panel_routine = ctk.CTkFrame(parent)
        self.right_panel_routine.pack(side="left", fill="both", expand=True, padx=10, pady=10)
        self.lbl_routine_detail = ctk.CTkLabel(self.right_panel_routine, text="Selecciona una rutina", font=("Courier", 12), justify="left", anchor="nw")
        self.lbl_routine_detail.pack(fill="both", expand=True, padx=10, pady=10)

    def show_routine_details(self, routine):
        import json
        formatted_json = json.dumps(routine, indent=2)
        self.lbl_routine_detail.configure(text=formatted_json)

    def show_create_routine_dialog(self):
        # TODO: Implementar un Dialogo complejo para construir JSON de rutina
        # Por ahora, haremos algo simple para demostrar la funcionalidad
        CreateRoutineDialog(self)

    # ... Metodos auxiliares mantienen su logica ...


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

# --- MODALES ADICIONALES ---

class CreateRoutineDialog(ctk.CTkToplevel):
    def __init__(self, parent):
        super().__init__(parent)
        self.parent = parent
        self.title("Crear Rutina Pública")
        self.geometry("600x700")
        self.attributes("-topmost", True)
        
        self.added_exercises_data = [] # Lista temporal para luego agrupar

        # 1. Datos Generales
        frm_basic = ctk.CTkFrame(self)
        frm_basic.pack(fill="x", padx=10, pady=10)
        
        ctk.CTkLabel(frm_basic, text="Nombre Rutina:").pack(side="left", padx=5)
        self.entry_name = ctk.CTkEntry(frm_basic, width=300)
        self.entry_name.pack(side="left", padx=5)

        # 2. Selector de Ejercicios
        frm_select = ctk.CTkFrame(self)
        frm_select.pack(fill="x", padx=10, pady=5)
        ctk.CTkLabel(frm_select, text="Agregar Ejercicios", font=("Roboto", 14, "bold")).pack(pady=5)
        
        # Combos
        self.group_options = {g['name']: g for g in self.parent.current_groups}
        group_names = list(self.group_options.keys())
        
        self.cmb_groups = ctk.CTkComboBox(frm_select, values=group_names, command=self.on_group_change)
        self.cmb_groups.pack(pady=2)
        
        self.cmb_subgroups = ctk.CTkComboBox(frm_select, command=self.on_subgroup_change)
        self.cmb_subgroups.pack(pady=2)
        
        self.cmb_exercises = ctk.CTkComboBox(frm_select)
        self.cmb_exercises.pack(pady=2)

        # Reps/Sets
        frm_reps = ctk.CTkFrame(frm_select, fg_color="transparent")
        frm_reps.pack(pady=5)
        ctk.CTkLabel(frm_reps, text="Sets:").pack(side="left", padx=2)
        self.entry_sets = ctk.CTkEntry(frm_reps, width=50)
        self.entry_sets.insert(0, "4")
        self.entry_sets.pack(side="left", padx=2)
        
        ctk.CTkLabel(frm_reps, text="Reps:").pack(side="left", padx=2)
        self.entry_reps = ctk.CTkEntry(frm_reps, width=50)
        self.entry_reps.insert(0, "12")
        self.entry_reps.pack(side="left", padx=2)

        ctk.CTkButton(frm_select, text="Agregar a la lista", command=self.add_exercise_to_list).pack(pady=10)

        # 3. Lista Previa
        self.txt_preview = ctk.CTkTextbox(self)
        self.txt_preview.pack(fill="both", expand=True, padx=10, pady=5)
        self.txt_preview.insert("0.0", "Resumen de la rutina:\n")

        # 4. Botones
        ctk.CTkButton(self, text="Guardar Rutina Global", fg_color="green", command=self.save_routine).pack(pady=10)
        self.lbl_msg = ctk.CTkLabel(self, text="")
        self.lbl_msg.pack()

        # Init combos
        if group_names: 
            self.cmb_groups.set(group_names[0])
            self.on_group_change(group_names[0])

    def on_group_change(self, group_name):
        self.selected_group_data = self.group_options.get(group_name)
        if not self.selected_group_data: return
        
        subs = self.selected_group_data.get('subgroups', [])
        self.subgroup_options = {s['name']: s for s in subs}
        sub_names = list(self.subgroup_options.keys())
        
        self.cmb_subgroups.configure(values=sub_names)
        if sub_names:
            self.cmb_subgroups.set(sub_names[0])
            self.on_subgroup_change(sub_names[0])
        else:
            self.cmb_subgroups.set("")
            self.cmb_exercises.configure(values=[])

    def on_subgroup_change(self, sub_name):
        self.selected_sub_data = self.subgroup_options.get(sub_name)
        if not self.selected_sub_data: return

        exs = self.selected_sub_data.get('exercises', [])
        self.exercise_options = {e['name']: e for e in exs}
        ex_names = list(self.exercise_options.keys())
        
        self.cmb_exercises.configure(values=ex_names)
        if ex_names: self.cmb_exercises.set(ex_names[0])
        else: self.cmb_exercises.set("")

    def add_exercise_to_list(self):
        ex_name = self.cmb_exercises.get()
        if not ex_name or ex_name not in self.exercise_options: return
        
        ex_data = self.exercise_options[ex_name]
        
        try:
            sets = int(self.entry_sets.get())
            reps = int(self.entry_reps.get())
        except:
            return # Error visual ignorado por tiempo

        # Guardamos en la estructura plana temporal
        item = {
            "group_name": self.selected_group_data['name'], # ej: Púrpura
            "group_code": self.selected_group_data.get('code', 'UNK'),
            "subgroup_name": self.selected_sub_data['name'], # ej: Pecho
            "exercise_name": ex_name,
            "exercise_id": ex_data.get('id') or ex_data.get('_id'),
            "target_sets": sets,
            "target_reps": reps
        }
        self.added_exercises_data.append(item)
        
        # Update UI
        line = f"- [{item['group_name']}] {item['exercise_name']} ({sets}x{reps})\n"
        self.txt_preview.insert("end", line)

    def save_routine(self):
        name = self.entry_name.get()
        if not name:
            self.lbl_msg.configure(text="Falta el nombre", text_color="red")
            return
        
        if not self.added_exercises_data:
            self.lbl_msg.configure(text="Agrega al menos un ejercicio", text_color="red")
            return

        # Transformar flat list -> Nested JSON para la API
        groups_map = {} 

        for item in self.added_exercises_data:
            g_name = item['group_name']
            if g_name not in groups_map:
                groups_map[g_name] = {
                    "name": g_name,
                    "code": item['group_code'],
                    "exercises": []
                }
            
            groups_map[g_name]['exercises'].append({
                "subgroup_name": item['subgroup_name'],
                "exercise_name": item['exercise_name'],
                "exercise_id": item['exercise_id'],
                "target_sets": item['target_sets'],
                "target_reps": item['target_reps']
            })
        
        payload = {
            "name": name,
            "is_public": True,
            "groups": list(groups_map.values())
        }

        self.lbl_msg.configure(text="Enviando...", text_color="blue")
        self.update()

        ok, resp = self.parent.client.create_routine(payload)
        if ok:
            self.lbl_msg.configure(text="¡Rutina Creada!", text_color="green")
            self.parent.load_data_and_show_dashboard() 
            self.after(1000, self.destroy)
        else:
            self.lbl_msg.configure(text=f"Error: {resp}", text_color="red")

if __name__ == "__main__":
    app = AdminApp()
    app.mainloop()

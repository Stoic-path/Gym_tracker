import customtkinter as ctk
from api_client import GymTrackerClient
from config import API_BASE_URL

ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class AdminApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Gym Tracker Admin")
        self.geometry("600x400")
        self.client = GymTrackerClient()

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

        label = ctk.CTkLabel(frame, text="Admin Login", font=("Roboto", 24))
        label.pack(pady=12, padx=10)

        self.entry_user = ctk.CTkEntry(frame, placeholder_text="Username")
        self.entry_user.pack(pady=12, padx=10)

        self.entry_pass = ctk.CTkEntry(frame, placeholder_text="Password", show="*")
        self.entry_pass.pack(pady=12, padx=10)

        button = ctk.CTkButton(frame, text="Ingresar", command=self.login_event)
        button.pack(pady=12, padx=10)

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
            self.after(1000, self.show_dashboard)
        else:
            self.lbl_status.configure(text=f"Error: {message}", text_color="red")

    def show_dashboard(self):
        self.clear_screen()
        
        # Sidebar
        sidebar = ctk.CTkFrame(self, width=140, corner_radius=0)
        sidebar.pack(side="left", fill="y")
        
        lbl_logo = ctk.CTkLabel(sidebar, text="Gym Tracker", font=("Roboto", 20, "bold"))
        lbl_logo.pack(padx=20, pady=20)

        btn_exercises = ctk.CTkButton(sidebar, text="Ejercicios", command=lambda: print("Ejercicios"))
        btn_exercises.pack(padx=20, pady=10)
        
        btn_logout = ctk.CTkButton(sidebar, text="Salir", fg_color="red", command=self.show_login_screen)
        btn_logout.pack(padx=20, pady=20, side="bottom")

        # Main Area
        main_frame = ctk.CTkFrame(self)
        main_frame.pack(side="right", fill="both", expand=True, padx=20, pady=20)

        lbl_welcome = ctk.CTkLabel(main_frame, text="Bienvenido al Panel de Administración", font=("Roboto", 18))
        lbl_welcome.pack(pady=20)

        # Test Connection to Exercise Service
        success, data = self.client.get_groups()
        status_text = "Conexión a Exercise Service: OK" if success else f"Error Exercise Service: {data}"
        color = "green" if success else "orange"
        
        lbl_conn = ctk.CTkLabel(main_frame, text=status_text, text_color=color)
        lbl_conn.pack(pady=10)

if __name__ == "__main__":
    app = AdminApp()
    app.mainloop()

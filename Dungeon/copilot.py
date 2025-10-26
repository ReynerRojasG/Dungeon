from PIL import Image
import os
import tkinter as tk
from tkinter import filedialog, messagebox

# Paleta VGA de 16 colores
vga_palette = {
    (0, 0, 0): '0',         # Negro
    (0, 0, 170): '1',       # Azul
    (0, 170, 0): '2',       # Verde
    (0, 170, 170): '3',     # Cyan
    (170, 0, 0): '4',       # Rojo
    (170, 0, 170): '5',     # Magenta
    (170, 85, 0): '6',      # Marrón
    (170, 170, 170): '7',   # Blanco
    (85, 85, 85): '8',      # Gris oscuro
    (85, 85, 255): '9',     # Azul claro
    (85, 255, 85): 'A',     # Verde claro
    (85, 255, 255): 'B',    # Cyan claro
    (255, 85, 85): 'C',     # Rojo claro
    (255, 85, 255): 'D',    # Magenta claro
    (255, 255, 85): 'E',    # Amarillo
    (255, 255, 255): 'F'    # Blanco brillante
}

# Inversa para visualización
hex_to_rgb = {v: k for k, v in vga_palette.items()}

def color_mas_cercano(r, g, b):
    menor_diferencia = float('inf')
    color_hex = '0'
    for (r_ref, g_ref, b_ref), hex_valor in vga_palette.items():
        diferencia = abs(r - r_ref) + abs(g - g_ref) + abs(b - b_ref)
        if diferencia < menor_diferencia:
            menor_diferencia = diferencia
            color_hex = hex_valor
    return color_hex

def convertir_a_txt():
    nombre_imagen = entrada_usuario.get()
    if not nombre_imagen:
        messagebox.showerror("Error", "Ingresa el nombre de la imagen")
        return

    path_imagen = os.path.abspath(nombre_imagen)
    nombre_txt = os.path.splitext(nombre_imagen)[0] + '.txt'
    path_txt = os.path.join(os.getcwd(), nombre_txt)

    try:
        img = Image.open(path_imagen).convert("RGB")
        ancho, alto = img.size
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo abrir la imagen: {e}")
        return

    with open(path_txt, 'w') as archivo:
        for y in range(alto):
            for x in range(ancho):
                r, g, b = img.getpixel((x, y))
                color = color_mas_cercano(r, g, b)
                archivo.write(color)
            archivo.write('@\n')
        archivo.write('$')

    messagebox.showinfo("Éxito", f"Archivo generado: {nombre_txt}")

def visualizar_txt():
    nombre_txt = entrada_usuario.get()
    if not nombre_txt.endswith('.txt'):
        nombre_txt += '.txt'
    path_txt = os.path.abspath(nombre_txt)

    try:
        with open(path_txt, 'r', encoding='utf-8') as archivo:
            lineas = archivo.readlines()
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo leer el archivo: {e}")
        return

    ancho = max(len(linea.strip('@\n')) for linea in lineas)
    alto = len(lineas)

    ventana = tk.Toplevel()
    ventana.title("Visualizador 8086")
    canvas = tk.Canvas(ventana, width=ancho, height=alto)
    canvas.pack()

    y = 0
    for linea in lineas:
        x = 0
        for caracter in linea.strip():
            if caracter == '@':
                y += 1
                break
            if caracter == '$':
                break
            color = hex_to_rgb.get(caracter, (0, 0, 0))
            canvas.create_rectangle(x, y, x+1, y+1, fill=f'#{color[0]:02x}{color[1]:02x}{color[2]:02x}', outline='')
            x += 1

def seleccionar_imagen():
    ruta = filedialog.askopenfilename(
        title="Selecciona una imagen PNG",
        filetypes=[("Imagen PNG", "*.png")]
    )
    entrada_usuario.delete(0, tk.END)
    entrada_usuario.insert(0, ruta)

def crear_interfaz():
    ventana = tk.Tk()
    ventana.title("Conversor 8086")

    global entrada_usuario
    entrada_usuario = tk.Entry(ventana, width=40)
    entrada_usuario.pack(pady=10)

    btn_seleccionar = tk.Button(ventana, text="Seleccionar imagen", command=seleccionar_imagen)
    btn_seleccionar.pack(pady=10)

    btn_convertir = tk.Button(ventana, text="Convertir imagen a .txt", command=convertir_a_txt)
    btn_convertir.pack(pady=10)

    btn_visualizar = tk.Button(ventana, text="Visualizar archivo .txt", command=visualizar_txt)
    btn_visualizar.pack(pady=10)

    ventana.mainloop()

crear_interfaz()

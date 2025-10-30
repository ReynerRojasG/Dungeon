from PIL import Image
import os
import tkinter as tk
from tkinter import filedialog, messagebox

# Paleta VGA de 16 colores
vga_palette = {
    (0, 0, 0): '0',
    (0, 0, 170): '1',
    (0, 170, 0): '2',
    (0, 170, 170): '3',
    (170, 0, 0): '4',
    (170, 0, 170): '5',
    (170, 85, 0): '6',
    (170, 170, 170): '7',
    (85, 85, 85): '8',
    (85, 85, 255): '9',
    (85, 255, 85): 'A',
    (85, 255, 255): 'B',
    (255, 85, 85): 'C',
    (255, 85, 255): 'D',
    (255, 255, 85): 'E',
    (255, 255, 255): 'F'
}

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
        # Convertimos a RGBA para poder leer la transparencia
        img = Image.open(path_imagen).convert("RGBA")
        ancho, alto = img.size
    except Exception as e:
        messagebox.showerror("Error", f"No se pudo abrir la imagen: {e}")
        return

    with open(path_txt, 'w') as archivo:
        for y in range(alto):
            for x in range(ancho):
                r, g, b, a = img.getpixel((x, y))

                # Si es totalmente transparente (alfa 0)
                if a == 0:
                    archivo.write('T')
                else:
                    color = color_mas_cercano(r, g, b)
                    archivo.write(color)
            archivo.write('@\n')
        archivo.write('$')

    messagebox.showinfo("Éxito", f"Archivo generado: {nombre_txt}")

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

    ventana.mainloop()

crear_interfaz()

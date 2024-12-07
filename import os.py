import os
import numpy as np
import re

# Configuración: define cómo calcular las paredes dinámicamente
def obtener_paredes(k):
    """
    Retorna los valores de wall_left y wall_right para un dado k.
    """
    wall_left = JCENTRE - (B / 2) - A * np.sin(2 * M_PI * k / ZMAX)
    wall_right = JCENTRE + (B / 2) - A * np.sin(2 * M_PI * k / ZMAX)
    return wall_left, wall_right

# Constantes
ZMAX = 504
A = 5
B = 20
ymax = 48
M_PI = 3.141592653589793
JCENTRE = ymax / 2
zmax = ZMAX

# Función para procesar un archivo individual
def procesar_archivo(archivo, zmax):
    tiempo = int(re.search(r"vel-(\d+)\.gplt", archivo).group(1))
    print(f"Procesando archivo: {archivo}, tiempo: {tiempo}")
    resultados_k = []

    with open(archivo, "r") as f:
        lineas = f.readlines()
        for k in range(1, zmax + 1):
            wall_left, wall_right = obtener_paredes(k)
            suma_vz = 0.0
            print(f"  Procesando k = {k}, paredes: wall_left={wall_left:.2f}, wall_right={wall_right:.2f}")
            for linea in lineas:
                valores = linea.split()
                if len(valores) == 6:
                    x, y, z, vx, vy, vz = map(float, valores)
                    if z == k and x == 1.0 and wall_left < y < wall_right:
                        suma_vz += vz
            print(f"    Suma de vz para k = {k}: {suma_vz:.6e}")
            resultados_k.append((k, suma_vz))

    # Guardar resultados de k y suma de vz en un archivo temporal
    output_file = f"vel-{tiempo}_processed.temp"
    with open(output_file, "w") as temp_file:
        for k, suma_vz in resultados_k:
            temp_file.write(f"{k} {suma_vz:.6e}\n")
    print(f"Archivo temporal generado: {output_file}")

    return tiempo, resultados_k

# Procesar todos los archivos vel-*.gplt
flujos_globales = []

for archivo in os.listdir("."):
    if archivo.startswith("vel-") and archivo.endswith(".gplt"):
        tiempo, resultados_k = procesar_archivo(archivo, zmax)
        flujos_globales.append((tiempo, [flujo for _, flujo in resultados_k]))

# Analizar los resultados globales
with open("flujo_final.txt", "w") as flujo_final:
    flujo_final.write("tiempo flujo_promedio flujo_max flujo_min\n")
    for tiempo, flujos in flujos_globales:
        suma_flujos = sum(flujos)
        flujo_max = max(flujos) if flujos else 0
        flujo_min = min(flujo for flujo in flujos if flujo != 0) if flujos else 0
        flujo_promedio = suma_flujos / 504
        flujo_final.write(f"{tiempo} {flujo_promedio:.6e} {flujo_max:.6e} {flujo_min:.6e}\n")
    print("Archivo flujo_final.txt generado con éxito.")

print("Procesamiento completado. Resultados guardados en flujo_final.txt")

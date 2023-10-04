# Establece la imagen base
FROM python:3.9

# Establece el directorio de trabajo en el contenedor
WORKDIR /app

# Copia el archivo de requisitos al directorio de trabajo
COPY requirements.txt .

# Instala las dependencias
RUN apt-get update && apt-get install -y \
    libhdf5-dev \
    build-essential \
    libgomp1 \
    libgl1-mesa-glx \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

# Copia el código fuente al directorio de trabajo
COPY . .

# Expone el puerto 8888
EXPOSE 8888

# Configura Jupyter Notebook como el comando por defecto para ejecutar la aplicación
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=..."]

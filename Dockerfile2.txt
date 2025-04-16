# Usa una imagen base de Linux ligera
FROM ubuntu:22.04

# Configura las variables de entorno
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin

# Instala dependencias básicas
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    wget \
    openjdk-17-jdk \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Descarga e instala Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME -b stable --depth 1
RUN flutter doctor

# Descarga e instala el Android SDK
RUN mkdir -p $ANDROID_HOME/cmdline-tools
RUN wget -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
RUN unzip cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools
RUN mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# Acepta las licencias del Android SDK
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Instala las herramientas necesarias del Android SDK
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Verifica la instalación de Flutter y Android
RUN flutter doctor -v

# Copia tu proyecto Flutter al contenedor
WORKDIR /app
COPY . .

# Instala las dependencias del proyecto
RUN flutter pub get

# Comando predeterminado para compilar el APK
CMD ["flutter", "build", "apk"]
# ==========================================
# Etapa 1: Compilación con Maven y Java 17
# ==========================================
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# Copiar archivos del wrapper de Maven y dependencias
COPY pom.xml mvnw ./
COPY .mvn .mvn

# Asegurar permisos de ejecución y corregir saltos de línea de Windows (CRLF a LF)
RUN sed -i 's/\r$//' mvnw && chmod +x ./mvnw

# Descargar dependencias para aprovechar la caché de Docker
RUN ./mvnw dependency:go-offline -B

# Copiar el código fuente y compilar omitiendo tests
COPY src ./src
RUN ./mvnw clean package -DskipTests

# ==========================================
# Etapa 2: Imagen final ligera para ejecución
# ==========================================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copiar el JAR generado
COPY --from=build /app/target/*.jar app.jar

# Optimización de memoria JVM para el plan gratuito de Render (512 MB de RAM)
ENV JAVA_OPTS="-XX:+UseSerialGC -Xss512k -XX:MaxRAMPercentage=75.0"

# Puerto por defecto (Render inyectará la variable $PORT automáticamente)
EXPOSE 8081

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

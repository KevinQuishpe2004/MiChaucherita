# MiChaucherita 💰

Una aplicación móvil moderna de gestión de finanzas personales construida con Flutter y Supabase.

## 📱 Características

### ✅ Implementadas
- **Autenticación de usuarios** con Supabase Auth (registro y login seguro)
- **Dashboard interactivo** con resumen de balance, ingresos y gastos mensuales
- **Gestión de cuentas** múltiples (efectivo, banco, tarjetas, ahorros)
- **Registro de transacciones** (ingresos, gastos y transferencias)
- **Categorización** de gastos e ingresos con iconos personalizados
- **Estadísticas visuales** con gráficos de torta y barras interactivos
- **Filtros inteligentes** por tipo de transacción y fecha
- **Backend en la nube** con Supabase (PostgreSQL)
- **Material Design 3** con tema personalizado
- **Animaciones fluidas** para mejor UX

### 🔐 Seguridad
- Autenticación segura con Supabase Auth
- Row Level Security (RLS) en base de datos
- Sesiones persistentes
- Datos sincronizados en la nube
- Rutas protegidas con autenticación

## 🚀 Configuración del Proyecto

### Prerrequisitos
- Flutter SDK 3.x o superior
- Cuenta en [Supabase](https://supabase.com)
- Android Studio / VS Code con extensiones de Flutter

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/CesarPantoja1/MiChaucherita.git
   cd MiChaucherita
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Supabase**
   
   a. Crea un proyecto en [Supabase](https://supabase.com)
   
   b. Ejecuta el script SQL en tu proyecto:
      - Ve a SQL Editor en el dashboard de Supabase
      - Copia y ejecuta el contenido de `supabase_init.sql`
   
   c. Configura las credenciales:
      - Copia `lib/core/config/supabase_config.example.dart` a `lib/core/config/supabase_config.dart`
      - Abre el archivo y reemplaza:
        * `TU_SUPABASE_URL_AQUI` con tu Project URL
        * `TU_SUPABASE_ANON_KEY_AQUI` con tu anon public key
      - Encuentra estas credenciales en: Settings > API

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🏗️ Arquitectura

### Clean Architecture + BLoC Pattern
```
lib/
├── core/
│   ├── constants/       # Colores, tamaños, strings
│   ├── data/           # DatabaseHelper, Repositories
│   ├── di/             # Service Locator (GetIt)
│   ├── domain/         # Modelos de datos
│   ├── router/         # Navegación (GoRouter)
│   ├── services/       # SessionService
│   ├── theme/          # Material Theme
│   └── widgets/        # Widgets reutilizables
└── features/
    ├── auth/           # Login, Registro (BLoC)
    ├── accounts/       # Gestión de cuentas (BLoC)
    ├── dashboard/      # Página principal
    ├── transactions/   # CRUD transacciones (BLoC)
    ├── statistics/     # Gráficos y reportes
    └── settings/       # Configuración y perfil
```

## 🛠️ Stack Tecnológico

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart 3.10.3+
- **Backend**: Supabase (PostgreSQL + Auth)
- **Estado**: flutter_bloc 8.1.6
- **Navegación**: go_router 14.6.2
- **DI**: get_it 8.0.2
- **Gráficos**: fl_chart 0.69.2
- **Animaciones**: flutter_animate 4.5.0
- **UI**: Material Design 3 + Iconsax

## 📦 Instalación

### Prerrequisitos
- Flutter SDK 3.10.0 o superior
- Dart SDK 3.10.3 o superior
- Android Studio / VS Code
- Java 17 (para builds de Android)

### Pasos

1. **Clonar el repositorio**
```bash
git clone [URL_DEL_REPO]
cd MiChaucherita
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la app**
```bash
flutter run
```

## 🚀 Deployment a Play Store

### 1. Crear Keystore de Producción

Sigue las instrucciones detalladas en [SIGNING_INSTRUCTIONS.md](SIGNING_INSTRUCTIONS.md)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Configurar key.properties

Crear `android/key.properties`:
```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3. Build de Producción

```bash
# APK
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

### 4. Preparar Assets para Play Store

- **Screenshots**: Toma capturas de pantalla en dispositivos de diferentes tamaños
- **Icono**: Debe ser 512x512px
- **Feature Graphic**: 1024x500px
- **Descripción corta**: Máximo 80 caracteres
- **Descripción completa**: Hasta 4000 caracteres
- **Política de privacidad**: Sube [PRIVACY_POLICY.md](PRIVACY_POLICY.md) a una URL pública

## 🔧 Configuración

### Versión de la App

Edita `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version+buildNumber
```

### SDK Versions

Configurado en `android/app/build.gradle.kts`:
- **minSdk**: 21 (Android 5.0)
- **targetSdk**: 34 (Android 14)
- **compileSdk**: 34

### Permisos

Declarados en `AndroidManifest.xml`:
- `INTERNET` - Para futuras funcionalidades de sync
- `ACCESS_NETWORK_STATE` - Verificar conectividad

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests (cuando estén implementados)
flutter test integration_test
```

## 📄 Base de Datos

### Esquema SQLite

#### Tabla: users
- id (INTEGER PRIMARY KEY)
- email (TEXT UNIQUE)
- password (TEXT - SHA256)
- name (TEXT)
- createdAt (TEXT)
- lastLoginAt (TEXT)

#### Tabla: accounts
- id (INTEGER PRIMARY KEY)
- name (TEXT)
- type (TEXT)
- balance (REAL)
- currency (TEXT)
- isActive (INTEGER)
- createdAt (TEXT)
- userId (INTEGER FK)

#### Tabla: categories
- id (INTEGER PRIMARY KEY)
- name (TEXT)
- type (TEXT - income/expense/transfer)
- icon (TEXT)
- color (TEXT)
- isActive (INTEGER)

#### Tabla: transactions
- id (INTEGER PRIMARY KEY)
- accountId (INTEGER FK)
- categoryId (INTEGER FK)
- type (TEXT)
- amount (REAL)
- description (TEXT)
- date (TEXT)
- createdAt (TEXT)
- userId (INTEGER FK)

## 🐛 Problemas Conocidos / TODOs

- [ ] Implementar carga dinámica de categorías desde base de datos
- [ ] Agregar página de creación/edición de cuentas
- [ ] Implementar búsqueda de transacciones
- [ ] Agregar filtros avanzados de transacciones
- [ ] Implementar exportación de datos (CSV/PDF)
- [ ] Agregar soporte para múltiples monedas
- [ ] Implementar backup en la nube (opcional)
- [ ] Agregar dark mode completo
- [ ] Implementar notificaciones de recordatorios
- [ ] Agregar biometría para login

## 📝 Licencia

[Elige tu licencia - MIT, Apache 2.0, etc.]

## 👥 Contribuir

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📧 Contacto

**Desarrollador**: [Tu Nombre]
**Email**: [tu_email@ejemplo.com]
**Website**: [tu_website]

## 🙏 Agradecimientos

- [Flutter](https://flutter.dev/)
- [Material Design](https://m3.material.io/)
- [Iconsax](https://pub.dev/packages/iconsax)
- [fl_chart](https://pub.dev/packages/fl_chart)

---

**Made with ❤️ and Flutter**

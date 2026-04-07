# Mapa del Sistema - gym PULSE

Aquí tienes el organigrama actualizado de cómo ha quedado estructurado tu proyecto en Flutter (`lib/`) luego de aplicar las mejores prácticas y convertirlo en un sistema por capas robusto y modular.

## Estructura de Directorios (`/lib`)

```text
lib/
├── models/                     ⬅️ (Capa de Dominio) - El "cerebro" de los datos
│   ├── category_model.dart     - Define qué es una Categoría y cómo se lee desde Supabase
│   ├── class_model.dart        - Define una Clase y conecta su categoría asociada
│   ├── instructor_model.dart   - Define a un Instructor
│   └── schedule_model.dart     - Define un Horario de Clase y anida instructores/clases
│
├── providers/                  ⬅️ (Capa de Estado Global) - Memoria Viva de la App
│   └── user_session.dart       - Guarda tu rol (Cliente/Admin) y estado de autenticación
│
├── screens/                    ⬅️ (Capa UI / Componentes Visuales) - Lo que ve el usuario
│   ├── admin_page.dart         - Dashboard del Admin. Protegido con Guards.
│   ├── create_edit_class.dart  - Formulario de creación/edición exclusiva para el Admin
│   ├── home_page.dart          - Vista de Cliente (Categorías, Workouts, Check-ins)
│   ├── login_page.dart         - Pasarela de Acceso principal
│   └── register_page.dart      - Creación de nuevas cuentas de gimnasio
│
├── services/                   ⬅️ (Capa de Servicio) - Interacción con el "Mundo Exterior"
│   └── supabase_service.dart   - Archivo único que habla con la Base de Datos. Pide 
│                                 JSON crudos y los devuelve convertidos en Modelos.
│
└── main.dart                   ⬅️ El 'Motor de Arranque'. Inicializa Supabase y los Providers
```

## Explicación por Capas del "Viaje de un Dato"
Para que lo visualices más fácil, mira este recorrido cuando un usuario entra a su pantalla de *Home*:

1. **`home_page.dart` (UI)** se enciende y dice: *"Oye `supabase_service`, pásame las clases de hoy"*. **Pausa:** La UI no sabe nada de bases de datos, contraseñas o URLs, solo llama una función.
2. **`supabase_service.dart` (Servicio)** toma ese pedido y hace la llamada segura a tu tabla en Supabase.
3. El servidor le responde con un **JSON crudo** (texto de máquina plano `[{ "class_id": 1, ... }]`).
4. Siguiendo en el `supabase_service`, antes de dárselo a la UI, usa los **`models/` (Capa de Dominio)** para "transformar" en milisegundos ese texto plano a un objeto real y seguro en Flutter.
5. Finalmente, el **Servicio** se voltea hacia **`home_page`** y le dice: *"Toma, aquí tienes un listado de `ClassModel`, está libre de errores de tipeo y 100% verificado"*.
6. Al mismo tiempo, si la pantalla tiene que ocultar o mostrar algo, consulta a **`user_session.dart` (Provider)**: *"¿Qué rol soy?"*. Y actúa en consecuencia cerrando sesión, permitiendo editar, o redirigiendo.

> [!TIP]
> **¿Por qué esta estructura es superior para escalar?**
> Imagina dentro de un año que digas: *"Quiero que el Home en vez de mostrar una lista vertical, use un abanico 3D"*. Vas directo a `screens/home_page.dart` y lo destruyes. Y no corres \*\*ningún riesgo\*\* de borrar la conexión a base de datos o dañar cómo funcionan los instructores.
>
> Oh, ¿y si ahora quieres que la base de datos no sea Supabase sino conectar tu propia API en Python? No tocas nada de `screens/`. Vas directo a `services/supabase_service.dart`, cambias la URL a donde apunta, y como sigues devolviendo objetos de `models/`, tu frontend en Flutter no sentirá \*\*ningún cambio\*\*. Seguirá funcionando mágicamente.

# Arquitectura del Sistema - gym PULSE

Este documento describe la arquitectura implementada en la aplicación móvil Flutter de gym PULSE tras la migración a un modelo de Capas Fuertemente Tipadas.

## Visión General de la Arquitectura (Clean Architecture Simplificada)

La aplicación ahora está separada en **3 capas distintas**, permitiendo que cada una tenga su propia responsabilidad. Si cambiamos la Base de Datos mañana, sólo afecta una capa; si cambiamos el Frontend, afecta a otra.

```mermaid
graph TD
    %% Define Styles
    classDef ui fill:#0F172A,stroke:#3B82F6,stroke-width:2px,color:#fff;
    classDef model fill:#1E293B,stroke:#0BDA54,stroke-width:2px,color:#fff;
    classDef state fill:#334155,stroke:#F59E0B,stroke-width:2px,color:#fff;
    classDef service fill:#0F2123,stroke:#00BDD6,stroke-width:2px,color:#fff;
    classDef db fill:#2A2A2A,stroke:#EF4444,stroke-width:2px,color:#fff;

    %% Components
    subgraph UI_Layer ["Capa de Presentación (UI)"]
        HomePage[HomePage]:::ui
        AdminPage[AdminPage]:::ui
        EditClass[CreateEditClassPage]:::ui
    end

    subgraph State_Layer ["Capa de Estado (Providers)"]
        UserSession[UserSession]:::state
    end

    subgraph Domain_Layer ["Capa de Dominio (Modelos de Datos)"]
        ClassModel[ClassModel]:::model
        CategoryModel[CategoryModel]:::model
        InstructorModel[InstructorModel]:::model
        ScheduleModel[ScheduleModel]:::model
    end

    subgraph Service_Layer ["Capa de Servicio (Conexión)"]
        SupabaseSvc[SupabaseService]:::service
    end

    subgraph DB_Layer ["Base de Datos (PostgreSQL)"]
        SupaDB[(Supabase DB)]:::db
    end

    %% Relationships
    HomePage -->|Consume| ClassModel
    AdminPage -->|Consume| ScheduleModel
    EditClass -->|Consume| CategoryModel
    
    HomePage -->|Pide Datos a| SupabaseSvc
    AdminPage -->|Pide Datos a| SupabaseSvc
    EditClass -->|Pasa / Pide Modelos a| SupabaseSvc
    
    SupabaseSvc -.->|Parsea JSON en| ClassModel
    SupabaseSvc -.->|Parsea JSON en| ScheduleModel
    
    HomePage -->|Lee Rol de| UserSession
    AdminPage -->|Lee Rol / App Guards| UserSession
    
    SupabaseSvc <==>|Peticiones Seguras (RLS)| SupaDB
```

## Cambios Clave Implementados

### 1. Modelos Fuertemente Tipados (Models)
**Antes**: Las pantallas manejaban datos usando diccionarios crudos `Map<String, dynamic>`, como `clase['name']`. Un error tipográfico como `clase['Name']` provocaba que la app crasheara al ejecutarla en el teléfono.
**Ahora**: Usamos clases reales (`ClassModel`, `ScheduleModel`). Accedemos a los datos con el punto `clase.name`. Si escribimos mal una propiedad, el compilador lanza error antes de que la aplicación arranque, previniendo bugs en producción.

### 2. Conversión Automática y Desacoplamiento (Services)
El `SupabaseService` ahora intercepta el diccionario de datos crudos (JSON) que llega desde Internet y lo transforma inmediatamente en los Modelos de la app.
De esta manera, las pantallas `HomePage` y `AdminPage` nunca tocan un dato tipo "Supabase", solo saben que se les devuelve "Una Clase" o "Un Horario". 

### 3. Middleware Manual de Seguridad (UI Guards)
Debido a que el router nativo de Flutter es imperativo directo.
Se ha colocado una "guarda" (Guard) de seguridad al inicio de pantallas confidenciales (**AdminPage** y **CreateEditClassPage**). Al momento en que el usuario intenta entrar e instanciar la pantalla, la app detiene el dibujado, comprueba en `UserSession` (Provider) si la persona tiene permisos de Admin y, si es un cliente normal, es empujado (Redirected) a la pantalla de Login con un reemplazo de ruta. Así se protege la vista ante curiosos.

## Casos de Uso Futuros

| Escenario de Cambio | Dónde se modifica | Impacto |
|---------------------|-------------------|---------|
| **Renombrar una columna en BD** (ej. *'name'* a *'title'*) | Modificar el `fromJson` del Modelo. | Transparente. Ninguna pantalla se rompe. |
| **Cambiar Supabase por Firebase** | Crear un `FirebaseService` que devuelva `ClassModel`s. | Bajo impacto. La UI ni se entera. |
| **Cambiar Flujo Visual (Botones, Colores)** | Se edita la carpeta limpia de Screens. | Nulo sobre la lógica o la BD. |
| **Pasar el Front a React JS (Web)** | Se debe rehacer la UI en React. | Todo el backend y RLS quedan intactos en Supabase. |

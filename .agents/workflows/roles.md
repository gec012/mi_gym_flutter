---
description: 
---

Actúa como un experto en Flutter y Supabase.

Analiza la tabla 'profiles'. Necesito implementar una lógica post-login que:

Obtenga el ID del usuario autenticado actual.

Realice una consulta a la tabla 'profiles' para obtener el campo 'role'.

Guarde este rol en un estado global (o Provider/Riverpod) para que la aplicación sea consciente de si el usuario es 'admin' o 'cliente'. Asegúrate de manejar errores si el perfil no existe.

Si el usuario es role:cliente debe navegar a la pagina home_page.dart. Si el usuario es role:admin debe navegar a la pagina admin_dashboard_page.dart.
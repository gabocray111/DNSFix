# Política de Seguridad

Gracias por tu interés en mejorar la seguridad de este proyecto.  
Este repositorio contiene un script por lotes (`.bat`) diseñado para diagnosticar problemas de conexión y, con autorización del usuario, modificar temporalmente la configuración DNS de Windows.  
La seguridad es una prioridad, incluso en herramientas pequeñas.

## 📌 Reportar una vulnerabilidad

Si encuentras un posible problema de seguridad, por favor repórtalo de manera privada:

- **Correo:** gabocray111@proton.me

No abras un issue público para vulnerabilidades que puedan poner en riesgo a otros usuarios.

## 🔍 Tipos de vulnerabilidades que deben reportarse

Por favor reporta si notas:

- Comandos que puedan ejecutarse sin confirmación cuando deberían solicitar permiso.
- Cualquier posibilidad de escalado de privilegios no intencional.
- Modificaciones de red que puedan persistir sin intención del usuario.
- Bypass de confirmaciones administrativas.
- Riesgos de inyección de comandos en entradas del usuario (por ejemplo, IP personalizada mal validada).
- Problemas que puedan causar que el script altere configuraciones críticas sin revertirlas adecuadamente.
- Descargas inseguras, ejecución remota o acceso no autorizado (aunque no deberían ocurrir en este proyecto).

## ❌ Cosas que **no** se consideran fallas de seguridad

No se consideran vulnerabilidades:

- El script no funcionando por configuración incorrecta en el equipo del usuario.
- Errores temporales causados por la red del usuario o por su proveedor de Internet.
- Advertencias estándar de Windows SmartScreen (ocurre con cualquier archivo BAT).
- Resultados de usar el script sin permisos de administrador cuando son necesarios.
- Confusiones por versiones antiguas del script o repositorios clonados incorrectamente.

## 🛡️ Expectativas de respuesta

- Revisiones iniciales: **24–72 horas**.
- Respuesta completa y confirmación del problema: **hasta 5 días**.
- Si se confirma una vulnerabilidad, se publicará un aviso en GitHub previo al parche.

## ⚙️ Consideraciones de seguridad del script

Este script:

- **Solicita confirmación** antes de realizar cambios en la configuración DNS.
- Puede usar `netsh`, lo cual **requiere permisos de administrador** para ciertas acciones.
- No realiza cambios permanentes sin interacción del usuario.
- No descarga ni ejecuta software externo.
- No recopila información del sistema ni envía datos a terceros.

## 🔒 Buenas prácticas al usar el script

- Ejecuta siempre el archivo desde una fuente confiable (este repositorio).
- Revisa el contenido si tienes dudas (es un archivo de texto simple).
- Asegúrate de tener privilegios adecuados si deseas que las configuraciones se apliquen correctamente.

---

Gracias por ayudar a mantener este proyecto seguro.

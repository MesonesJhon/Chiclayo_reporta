# Solución para el Error 500 al Actualizar Estado del Reporte

## Problema Identificado

La API está verificando que el reporte pertenezca al usuario autenticado (`WHERE id = %s AND usuario_id = %s`), pero cuando un **administrador** intenta actualizar un reporte de otro usuario, esta verificación falla y causa un error 500.

## Solución: Modificar la API para Permitir a Administradores

Aquí está el código corregido para tu endpoint `/api/reportes/estado/<int:reporte_id>`:

```python
@app.route('/api/reportes/estado/<int:reporte_id>', methods=['PUT'])
@jwt_required
def actualizar_estado_reporte(reporte_id):
    try:
        user_id = request.user_id  # ID del usuario autenticado
        user_tipo = request.user_tipo  # Tipo de usuario (debe estar en tu JWT)
        
        data = request.get_json() or {}
        nuevo_estado = data.get('estado')

        # 1. Validar que haya estado
        if not nuevo_estado:
            return jsonify({
                "code": 0,
                "data": {},
                "message": "El campo 'estado' es obligatorio"
            }), 400

        # 2. Validar que sea uno de los permitidos
        if nuevo_estado not in ESTADOS_REPORTE_VALIDOS:
            return jsonify({
                "code": 0,
                "data": {
                    "estado_recibido": nuevo_estado,
                    "estados_permitidos": list(ESTADOS_REPORTE_VALIDOS)
                },
                "message": "Estado no válido"
            }), 400

        connection = obtenerconxion()
        with connection:
            with connection.cursor() as cursor:
                # 3. Verificar si el usuario es administrador
                es_admin = user_tipo and user_tipo.lower() in ['administrador', 'admin']
                
                # 4. Verificar que el reporte exista
                if es_admin:
                    # Si es admin, solo verificar que el reporte exista (sin verificar usuario_id)
                    cursor.execute("""
                        SELECT id, estado, usuario_id
                        FROM reportes
                        WHERE id = %s
                    """, (reporte_id,))
                else:
                    # Si no es admin, verificar que el reporte exista Y pertenezca al usuario
                    cursor.execute("""
                        SELECT id, estado, usuario_id
                        FROM reportes
                        WHERE id = %s AND usuario_id = %s
                    """, (reporte_id, user_id))
                
                reporte = cursor.fetchone()
                
                if not reporte:
                    if es_admin:
                        return jsonify({
                            "code": 0,
                            "data": {},
                            "message": "Reporte no encontrado"
                        }), 404
                    else:
                        return jsonify({
                            "code": 0,
                            "data": {},
                            "message": "Reporte no encontrado o no pertenece al usuario"
                        }), 404

                # 5. Actualizar el estado
                cursor.execute("""
                    UPDATE reportes
                    SET estado = %s,
                        fecha_actualizacion = NOW()
                    WHERE id = %s
                """, (nuevo_estado, reporte_id))

                # 6. Obtener el reporte actualizado
                cursor.execute("""
                    SELECT
                        r.id AS reporte_id,
                        r.codigo_seguimiento,
                        r.titulo,
                        r.descripcion,
                        r.estado,
                        r.prioridad,
                        r.fecha_creacion,
                        r.fecha_actualizacion
                    FROM reportes r
                    WHERE r.id = %s
                """, (reporte_id,))
                
                reporte_actualizado = cursor.fetchone()

        return jsonify({
            "code": 1,
            "data": reporte_actualizado,
            "message": "Estado del reporte actualizado correctamente"
        }), 200

    except Exception as e:
        print("Error al actualizar estado del reporte:", e)
        import traceback
        traceback.print_exc()  # Imprimir el traceback completo para debugging
        return jsonify({
            "code": -1,
            "data": {},
            "message": f"Error interno del servidor: {str(e)}"
        }), 500
```

## Cambios Principales

1. **Verificación de rol de administrador**: Se verifica si el usuario es administrador antes de aplicar la restricción de `usuario_id`.

2. **Consulta condicional**: 
   - Si es **admin**: Solo verifica que el reporte exista (`WHERE id = %s`)
   - Si es **ciudadano**: Verifica que el reporte exista Y pertenezca al usuario (`WHERE id = %s AND usuario_id = %s`)

3. **Mejor manejo de errores**: Se agregó `traceback.print_exc()` para ver el error completo en los logs del servidor.

## Nota Importante sobre `request.user_tipo`

Asegúrate de que tu decorador `@jwt_required` o tu función de autenticación JWT esté agregando `user_tipo` al objeto `request`. Si no lo hace, necesitarás:

1. **Opción A**: Modificar tu decorador JWT para incluir `user_tipo` en `request`
2. **Opción B**: Hacer una consulta adicional a la base de datos para obtener el tipo de usuario:

```python
# Si no tienes user_tipo en request, agregar esto antes de la verificación:
cursor.execute("""
    SELECT tipo FROM usuarios WHERE id = %s
""", (user_id,))
usuario = cursor.fetchone()
user_tipo = usuario[0] if usuario else None
es_admin = user_tipo and user_tipo.lower() in ['administrador', 'admin']
```

## Verificación Adicional

Si sigues teniendo errores 500, verifica:

1. **Logs del servidor**: Revisa los logs de PythonAnywhere para ver el error exacto
2. **Conexión a BD**: Verifica que `obtenerconxion()` esté funcionando correctamente
3. **JWT Token**: Asegúrate de que el token incluya `user_id` y preferiblemente `user_tipo`
4. **Tabla reportes**: Verifica que la tabla tenga las columnas correctas y que el `reporte_id` exista

